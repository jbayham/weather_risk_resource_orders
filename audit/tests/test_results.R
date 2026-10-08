# End-to-end checks of unchanged benchmarks and corrected data/inference.
read_env <- function(mode){e<-new.env();load(file.path("audit-output",mode,"analysis/inputs/03_orders.Rdata"),e);load(file.path("audit-output",mode,"analysis/cache/results_resource_orders.Rdata"),e);e}
corr<-read_env("corrected");hist<-read_env("historical");old<-read_env("legacy")
stopifnot(nrow(corr$orders.ds)==nrow(hist$orders.ds),
          !anyDuplicated(corr$orders.ds[c("incident_number","report_date")]))
keep<-setdiff(names(corr$orders.ds),"ic_name")
stopifnot(isTRUE(all.equal(corr$orders.ds[keep],hist$orders.ds[keep],check.attributes=FALSE)))
stopifnot(nrow(old$orders.ds)>nrow(corr$orders.ds))
for(i in 1:3) stopifnot(max(abs(coef(corr$all.resources[[i]])-coef(hist$all.resources[[i]])))<1e-9)
# Rendering must use explicit clustered inference, with keyed variable names.
source("functions/analysis_functions.R")
for(m in corr$all.resources) {
 stopifnot(isTRUE(all.equal(unclass(fixest_to_coeftest(m)),unname(as.matrix(summary(m,se="cluster")$coeftable)),check.attributes=FALSE)))
}
x<-read.csv("report/audit/resource-coefficients-all-paths.csv")
stopifnot(all(x$label[x$term=="L1.growth"]=="Lagged Growth"),all(x$label[x$term=="evac_potential"]=="Potential Evacuation"))
pub<-read.csv("audit/tests/published-benchmarks.csv")
z<-merge(pub,x[x$variant=="historical",],by=c("model","term"));stopifnot(nrow(z)==91)
z$coefficient_match<-abs(z$estimate-z$coefficient)<=.00005
z$se_match<-abs(z$se.y-z$se.x)<=.00005
# Known published LAT interaction discrepancy is reported, not silently accepted.
write.csv(z,"report/audit/published-benchmark.csv",row.names=FALSE)
known<-z$model=="VLAT" & z$term=="growth_potentialHigh:evac_potential"
stopifnot(all(z$coefficient_match[!known]),all(z$se_match),!z$coefficient_match[known])
g<-read.csv("report/audit/growth-benchmark.csv")
stopifnot(max(abs(g$difference),na.rm=TRUE)<1e-10,max(abs(g$se_difference),na.rm=TRUE)<1e-10)
for(mode in c("corrected","historical","legacy")) stopifnot(all(vapply(read_env(mode)$all.resources,nobs,numeric(1))>0))
opt<-read.csv("report/audit/gp-optimizer-validation.csv")
stopifnot(all(opt$score_after_newton<1e-7),all(opt$score_vs_sandwich<1e-10))
cat("End-to-end checks passed: data cardinality, unchanged non-name data, Models 1–3, clustered rendering, published and saved benchmarks, ordered-logit validation.\n")

original<-new.env();rebuilt<-new.env()
load("build/cache/temp_ds.Rdata",original)
load("audit-output/corrected/build/cache/temp_ds.Rdata",rebuilt)
sort_cache<-function(d)d[order(d$incident_number,d$report_date),sort(names(d))]
stopifnot(isTRUE(all.equal(sort_cache(original$temp.ds),sort_cache(rebuilt$temp.ds),tolerance=1e-10,check.attributes=FALSE)))
cat("Rebuilt merged cache matches the archived cache at 1e-10 after sorting.\n")
