# R is the primary ordered-logit implementation. Original .do remains archival.
# See audit/README.md for the model, spline and inference choices.
library(haven); library(sandwich)
out <- "analysis/cache/gp"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
d <- as.data.frame(read_dta('analysis/inputs/02_gp_ds_stata.dta'))
for(v in names(d)) if(is.character(d[[v]])) d[[v]][d[[v]]==''] <- NA_character_
d$source_row <- seq_len(nrow(d))
# Stata encode with existing gp labels: ordered Low=1,...,Extreme=4.
d$growth_potential <- ordered(d$growth_potential,levels=c('Low','Medium','High','Extreme'))
d$terrain <- factor(d$terrain,levels=c('Low','Medium','High','Extreme'))
# encode default alphabetical ordering; year already has numeric codes 1:7.
d$gacc <- factor(d$gacc,levels=sort(unique(d$gacc),na.last=NA))
d$cause_descr <- factor(d$cause_descr,levels=sort(unique(d$cause_descr),na.last=NA))
d$year <- factor(as.numeric(d$year),levels=1:7)
d$sfwp <- factor(d$sfwp,levels=1:5)
# mkspline is BEFORE listwise deletion. Four knots: 5,35,65,95 percentiles.
knot_area <- d$area
knots <- as.numeric(quantile(knot_area,c(.05,.35,.65,.95),type=2,na.rm=TRUE))
xx<-sort(d$area[!is.na(d$area)]);knots[1]<-max(knots[1],xx[5]);knots[4]<-min(knots[4],xx[length(xx)-4])
rcs_stata <- function(x,k) {
 pos<-function(t)pmax(t,0)^3
 cbind(sp_area1=x,sp_area2=(pos(x-k[1])-(pos(x-k[3])*(k[4]-k[1])-pos(x-k[4])*(k[3]-k[1]))/(k[4]-k[3]))/(k[4]-k[1])^2,
 sp_area3=(pos(x-k[2])-(pos(x-k[3])*(k[4]-k[2])-pos(x-k[4])*(k[3]-k[2]))/(k[4]-k[3]))/(k[4]-k[1])^2)
}
basis <- rcs_stata(d$area,knots)
d<-cbind(d,basis);write.csv(data.frame(percentile=c(5,35,65,95),knot=knots),file.path(out,'spline-knots.csv'),row.names=FALSE)
controls<-c('gacc*doy_cos','cause_descr','terrain','year',paste0('PC',1:20),paste0('sp_area',1:3))
weather<-list(ol_all=c('prcp','rmin','tmax','wind','bi','erc','sfwp'),ol_raw=c('prcp','rmin','tmax','wind'),ol_index=c('bi','erc'),ol_sfwp='sfwp')
fits<-list();tables<-list();diagnostics<-list()
for(nm in names(weather)) {
 f<-as.formula(paste('growth_potential ~',paste(c(weather[[nm]],controls),collapse=' + ')))
 mf<-model.frame(f,d,na.action=na.pass)
 keep<-complete.cases(mf)&!is.na(d$ross_inc_id)
 ds<-d[keep,];X<-model.matrix(f,ds)[,-1,drop=FALSE];n<-nrow(X);p<-ncol(X)
 # Numerically stable invertible reparameterization, not a changed specification.
 mu<-colMeans(X);C<-sweep(X,2,mu);qrX<-qr(C);stopifnot(qrX$rank==p)
 Q<-qr.Q(qrX)*sqrt(n);R<-qr.R(qrX)/sqrt(n)
 B<-matrix(0,p,p);B[qrX$pivot,]<-solve(R)
 qd<-data.frame(y=ds$growth_potential,Q);names(qd)[-1]<-paste0('q',seq_len(p))
 cat('Fitting',nm,'N',n,'clusters',length(unique(ds$ross_inc_id)),'columns',p,'\n')
 fit<-MASS::polr(y~.,data=qd,method='logistic',Hess=TRUE,control=list(maxit=2000,reltol=1e-13))
 stopifnot(fit$convergence==0)
 A<-matrix(0,p+3,p+3);A[1:p,1:p]<-B;A[p+1:3,1:p]<-matrix(rep(drop(mu%*%B),each=3),3,p);A[p+1:3,p+1:3]<-diag(3)
 # polr and Stata use P(Y<=j)=logistic(cut_j-X beta).
 theta<-drop(A%*%c(coef(fit),fit$zeta));names(theta)<-c(colnames(X),paste0('cut',1:3))
 Vq<-vcovCL(fit,cluster=ds$ross_inc_id,type='HC0',cadjust=TRUE)
 V<-A%*%Vq%*%t(A);dimnames(V)<-list(names(theta),names(theta))
 tab<-data.frame(model=nm,term=names(theta),estimate=theta,se=sqrt(diag(V)),p=2*pnorm(-abs(theta/sqrt(diag(V)))),n=n,clusters=length(unique(ds$ross_inc_id)))
 tables[[nm]]<-tab
 eta<-drop(X%*%theta[1:p]);cum<-sapply(theta[p+1:3],function(z)plogis(z-eta));prob<-cbind(cum[,1],cum[,2]-cum[,1],cum[,3]-cum[,2],1-cum[,3]);colnames(prob)<-levels(ds$growth_potential)
 write.csv(data.frame(source_row=ds$source_row,ross_inc_id=ds$ross_inc_id,observed=ds$growth_potential,prob),file.path(out,paste0(nm,'-fitted-probabilities.csv')),row.names=FALSE)
 scores<-estfun(fit)
 diagnostics[[nm]]<-data.frame(model=nm,n=n,clusters=length(unique(ds$ross_inc_id)),logLik=as.numeric(logLik(fit)),convergence=fit$convergence,max_score_sum=max(abs(colSums(scores))),min_probability=min(prob),max_probability_sum_error=max(abs(rowSums(prob)-1)),min_hessian_eigen=min(eigen(fit$Hessian,symmetric=TRUE,only.values=TRUE)$values),condition_unscaled=kappa(X),condition_reparameterized=kappa(Q))
 fits[[nm]]<-list(model=fit,formula=f,data=ds,X=X,Q=Q,A=A,theta=theta,vcov=V,vcov_q=Vq,knots=knots,prob=prob)
 print(tab[seq_len(length(weather[[nm]])),])
}
write.csv(do.call(rbind,tables),file.path(out,'coefficients.csv'),row.names=FALSE)
write.csv(do.call(rbind,diagnostics),file.path(out,'fit-diagnostics.csv'),row.names=FALSE)
saveRDS(fits,file.path(out,'ordered-logit-fits.rds'))
source("functions/ordered_logit_inference.R")
source("analysis/code/02_growth_potential_margins.R")
