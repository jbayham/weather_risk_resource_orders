# Aggregate-only exports. Never copy row-level inputs, fitted observations or RDSs.
output <- "report/audit";dir.create(output,showWarnings=FALSE,recursive=TRUE)
resources <- c("Wildland_Engines","Structure_Engines","Dozers","Type_1_Crews","Type_2_Crews","VLAT","T2_4_Airtanker","Helicopters")
labels <- setNames(read.csv("report/var_names.csv")$new_name,read.csv("report/var_names.csv")$value)
labels["L1.growth"] <- "Lagged Growth"; labels["evac_potential"] <- "Potential Evacuation"
label <- function(term) {z<-unname(labels[term]);z[is.na(z)]<-term[is.na(z)];z}
rows<-list();sizes<-list();j<-0
for(mode in c("corrected","historical","legacy")) {
 e<-new.env();load(file.path("audit-output",mode,"analysis/cache/results_resource_orders.Rdata"),e)
 for(kind in c("all.resources","results.lm")) for(i in seq_along(e[[kind]])) {
  m<-e[[kind]][[i]];ct<-summary(m,se="cluster")$coeftable;j<-j+1
  model<-if(kind=="all.resources")paste0("Table4_",i) else resources[i]
  rows[[j]]<-data.frame(variant=mode,model=model,term=rownames(ct),label=label(rownames(ct)),estimate=ct[,1],se=ct[,2],p=ct[,4],n=nobs(m))
  sizes[[j]]<-data.frame(variant=mode,model=model,n=nobs(m),fires=unname(m$fixef_sizes["incident_number"]),
    days=if("time_since_disco"%in%names(m$fixef_sizes))unname(m$fixef_sizes["time_since_disco"]) else NA,
    commanders=if("ic_name"%in%names(m$fixef_sizes))unname(m$fixef_sizes["ic_name"]) else NA)
 }
}
coefs<-do.call(rbind,rows);write.csv(coefs,file.path(output,"resource-coefficients-all-paths.csv"),row.names=FALSE)
write.csv(do.call(rbind,sizes),file.path(output,"model-coverage.csv"),row.names=FALSE)
terms<-c("growth_potentialHigh","growth_potentialLow","L1.growth","evac_potential","L1.evac","growth_potentialHigh:evac_potential","growth_potentialLow:evac_potential","L1.growth:L1.evac")
selected<-coefs[coefs$variant=="corrected" & coefs$term%in%terms,]
for(tab in c("Table4","Table5","Table6")) {
 models<-switch(tab,Table4=paste0("Table4_",1:4),Table5=resources[c(1,2,4,5)],Table6=resources[c(6,7,8,3)])
 z<-selected[selected$model%in%models,];z<-z[order(match(z$model,models),match(z$term,terms)),]
 write.csv(z,file.path(output,paste0(tab,".csv")),row.names=FALSE)
}
# Compare the archival saved growth outputs without overwriting them.
files<-list.files("report/tables/need_formatting",pattern="^01_growth_wx.*csv$",full.names=TRUE)
growth<-lapply(files,function(f){
 a<-read.csv(f);b<-read.csv(file.path("audit-output/corrected",f));a$term[a$term=="Effron R2"]<-"Efron R2"
 z<-merge(a,b,by="term");data.frame(model=basename(f),term=z$term,expected=z$estimate.x,reproduced=z$estimate.y,
 difference=z$estimate.y-z$estimate.x,expected_se=z$std.error.x,reproduced_se=z$std.error.y,se_difference=z$std.error.y-z$std.error.x)
});write.csv(do.call(rbind,growth),file.path(output,"growth-benchmark.csv"),row.names=FALSE)
# All growth coefficients, and fresh numeric summaries for actual estimation samples.
e<-new.env();load("audit-output/corrected/analysis/cache/results_growth.Rdata",e)
load("audit-output/corrected/analysis/inputs/01_growth.Rdata",e)
growth_sample <- e$growth.ds[setdiff(seq_len(nrow(e$growth.ds)),e$output.growth[[1]]$na.action),]
gtabs<-lapply(seq_along(e$output.growth),function(i){m<-e$output.growth[[i]];idx<-setdiff(seq_len(nrow(e$growth.ds)),m$na.action)
 ct<-coeftest(m,vcov=vcovCL(m,cluster=e$growth.ds$ross_inc_id[idx]));data.frame(model=i,term=rownames(ct),label=label(rownames(ct)),estimate=ct[,1],se=ct[,2],p=ct[,4],n=nobs(m))})
write.csv(do.call(rbind,gtabs),file.path(output,"S2-growth.csv"),row.names=FALSE)
load("audit-output/corrected/analysis/cache/results_resource_orders.Rdata",e);load("audit-output/corrected/analysis/inputs/03_orders.Rdata",e)
order_sample<-e$orders.ds[setdiff(seq_len(nrow(e$orders.ds)),e$all.resources[[1]]$obsRemoved),]
gp<-readRDS("audit-output/corrected/analysis/cache/gp/ordered-logit-polished.rds")
variables<-c("L1.area","growth","L0.bi","L0.erc","L0.prcp","L0.rmin","L0.tmax","L0.wind",resources)
summary_numeric<-function(d,vars,model){do.call(rbind,lapply(intersect(vars,names(d)),function(v){x<-d[[v]];data.frame(model=model,variable=v,n=sum(!is.na(x)),mean=mean(x,na.rm=TRUE),sd=sd(x,na.rm=TRUE),min=min(x,na.rm=TRUE),max=max(x,na.rm=TRUE))}))}
sum3<-summary_numeric(order_sample,variables,"Resource orders");write.csv(sum3,file.path(output,"Table3.csv"),row.names=FALSE)
sum1<-rbind(sum3,summary_numeric(growth_sample,variables,"Realized growth"),summary_numeric(gp$ol_all$data,c("area","bi","erc","prcp","rmin","tmax","wind"),"Growth potential"))
write.csv(sum1,file.path(output,"S1-summary.csv"),row.names=FALSE)
for(f in c("coefficients.csv","margins.csv","optimizer-validation.csv","margins-validation.csv","fit-diagnostics.csv","spline-knots.csv"))
 stopifnot(file.copy(file.path("audit-output/corrected/analysis/cache/gp",f),file.path(output,paste0("gp-",f)),overwrite=TRUE))
stopifnot(file.copy("audit-output/corrected/report/tables/commander_audit.csv",output,overwrite=TRUE))
# Generated plots only, never paper pages or downloaded published assets.
figs<-list.files("audit-output/corrected/report/figures",pattern="\\.png$",full.names=TRUE)
dir.create(file.path(output,"figures"),showWarnings=FALSE)
stopifnot(all(file.copy(figs,file.path(output,"figures"),overwrite=TRUE)))
load("audit-output/corrected/analysis/cache/pca.Rdata",e)
png(file.path(output,"figures/PCA.png"),width=1000,height=650)
v<-summary(e$pca.output)$importance[3,];plot(seq_along(v),v,type="b",xlab="Principal component",ylab="Cumulative variance explained");abline(h=.8,col="red");dev.off()
write.csv(data.frame(package=required,version=vapply(required,function(p)as.character(packageVersion(p)),character(1))),file.path(output,"packages.csv"),row.names=FALSE)
writeLines(c(paste("R",getRversion()),paste("Platform:",R.version$platform),"Deterministic estimation with fixest threads=1; no resampling. Plot rug jitter seed: 20261008.","Base revision: 5fe40759ee4194f3a5a86926e1105fdc3b66ca0e"),file.path(output,"environment.txt"))
# Relative paths and content checksums, no personal system/library paths.
code<-c("report/Supplement.Rmd",list.files("audit",recursive=TRUE,full.names=TRUE),list.files("analysis/code",full.names=TRUE),list.files("functions",full.names=TRUE),list.files("build/code",full.names=TRUE))
code<-code[file.info(code)$isdir==FALSE];write.csv(data.frame(path=code,md5=unname(tools::md5sum(code))),file.path(output,"source-checksums.csv"),row.names=FALSE)

write.csv(data.frame(path=source_files,md5=unname(tools::md5sum(source_files))),file.path(output,"input-checksums.csv"),row.names=FALSE)
