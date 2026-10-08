library(numDeriv)
# Verify direct-cutpoint score and Hessian with numerical differentiation;
# polish Newton steps in the QR basis without changing model specification.
ll_parts <- function(par,X,y,hessian=TRUE) {
 n<-nrow(X);p<-ncol(X);b<-par[1:p];z<-par[p+1:3];eta<-drop(X%*%b)
 cuts<-c(-Inf,z,Inf);u<-cuts[y+1]-eta;l<-cuts[y]-eta
 Fu<-plogis(u);Fl<-plogis(l);fu<-dlogis(u);fl<-dlogis(l);prob<-Fu-Fl
 if(any(prob<=0)||any(diff(z)<=0))return(list(logLik=-Inf))
 su<-fu/prob;sl<--fl/prob;se<- (fl-fu)/prob
 S<-cbind(X*se,matrix(0,n,3))
 for(j in 1:3)S[,p+j]<-(y==j)*su+(y==j+1)*sl
 ans<-list(logLik=sum(log(prob)),score=S,prob=prob)
 if(hessian){
  fpu<-fu*(1-2*Fu);fpl<-fl*(1-2*Fl)
  H<-matrix(0,p+3,p+3);H[1:p,1:p]<-crossprod(X,X*((fpu-fpl)/prob-se^2))
  for(j in 1:3){
   v<-(y==j)*(-fpu/prob-se*su)+(y==j+1)*(fpl/prob-se*sl)
   H[1:p,p+j]<-colSums(X*v);H[p+j,1:p]<-H[1:p,p+j]
   H[p+j,p+j]<-sum((y==j)*(fpu/prob-su^2)+(y==j+1)*(-fpl/prob-sl^2))
   if(j<3){H[p+j,p+j+1]<-sum((y==j+1)*fu*fl/prob^2);H[p+j+1,p+j]<-H[p+j,p+j+1]}
  };ans$H<-H
 };ans
}
f<-readRDS(file.path(out,'ordered-logit-fits.rds'));results<-list()
for(nm in names(f)){
 a<-f[[nm]];p<-ncol(a$Q);y<-as.numeric(a$data$growth_potential);par<-c(coef(a$model),a$model$zeta);initial<-par
 v<-ll_parts(par,a$Q,y)
 score_agreement<-max(abs(v$score-estfun(a$model)))
 # Analytic Hessian vs numerical Jacobian of analytic gradient: independent check.
 Hnum<-jacobian(function(t)colSums(ll_parts(t,a$Q,y,FALSE)$score),par)
 hessian_agreement<-max(abs(v$H-Hnum))
 stopifnot(score_agreement < 1e-10, hessian_agreement / max(abs(v$H)) < 1e-6)
 for(i in 1:8){v<-ll_parts(par,a$Q,y);step<-solve(-v$H,colSums(v$score));if(max(abs(step))<1e-11)break
  scale<-1;while(ll_parts(par+scale*step,a$Q,y,FALSE)$logLik < v$logLik-1e-9){scale<-scale/2;if(scale<1e-7)stop('line search failed')};par<-par+scale*step
 }
 v<-ll_parts(par,a$Q,y);stopifnot(max(abs(colSums(v$score)))<1e-7);Hinv<-solve(-v$H);sg<-rowsum(v$score,a$data$ross_inc_id,reorder=FALSE);G<-nrow(sg);Vq<-Hinv%*%crossprod(sg)%*%Hinv*G/(G-1)
 polished<-drop(a$A%*%par);names(polished)<-names(a$theta)
 results[[nm]]<-data.frame(model=nm,score_vs_sandwich=score_agreement,hessian_vs_numDeriv=hessian_agreement,score_after_newton=max(abs(colSums(v$score))),logLik_before=as.numeric(logLik(a$model)),logLik_after=v$logLik,max_original_scale_coef_change=max(abs(polished-a$theta)),max_cluster_SE_change=max(abs(sqrt(diag(a$A%*%Vq%*%t(a$A)))-sqrt(diag(a$vcov)))))
 a$theta<-polished;a$vcov<-a$A%*%Vq%*%t(a$A);dimnames(a$vcov)<-list(names(polished),names(polished));a$theta_q<-par;a$vcov_q<-Vq;a$polished_logLik<-v$logLik
 f[[nm]]<-a
}
write.csv(do.call(rbind,results),file.path(out,'optimizer-validation.csv'),row.names=F)
saveRDS(f,file.path(out,'ordered-logit-polished.rds'))
print(do.call(rbind,results))

# Canonical exported comparisons use the independently polished solution.
coeffs<-list()
for(nm in names(f)){
 a<-f[[nm]];se<-sqrt(diag(a$vcov));coeffs[[nm]]<-data.frame(model=nm,term=names(a$theta),estimate=a$theta,se=se,p=2*pnorm(-abs(a$theta/se)),n=nrow(a$data),clusters=length(unique(a$data$ross_inc_id)))
}
write.csv(do.call(rbind,coeffs),file.path(out,'coefficients.csv'),row.names=FALSE)
