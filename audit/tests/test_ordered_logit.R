a<-readRDS(file.path(out,'ordered-logit-polished.rds'));ans<-list()
for(nm in names(a)){
 f<-a[[nm]];p<-ncol(f$X);q<-f$theta_q;b<-f$theta
 prob<-function(eta,z){cum<-cbind(0,sapply(z,function(k)plogis(k-eta)),1);cum[,-1]-cum[,-5]}
 p1<-prob(drop(f$Q%*%q[1:p]),q[p+1:3]);p2<-prob(drop(f$X%*%b[1:p]),b[p+1:3]);err<-max(abs(p1-p2));stopifnot(err<1e-8)
 # Numerical derivatives of mean probabilities, independent central differences.
 Q<-f$Q;eta<-drop(Q%*%q[1:p]);D<-cbind(0,sapply(q[p+1:3],function(k)dlogis(k-eta)),0)
 G<-matrix(0,4,p+3)
 for(j in 1:4){G[j,1:p]<-colMeans(Q*(D[,j]-D[,j+1]));if(j<=3)G[j,p+j]<-mean(D[,j+1]);if(j>=2)G[j,p+j-1]<--mean(D[,j])}
 idx<-c(1,2,p,p+1:3);h<-1e-5
 numeric<-sapply(idx,function(k){up<-dn<-q;up[k]<-up[k]+h;dn[k]<-dn[k]-h;(colMeans(prob(drop(Q%*%up[1:p]),up[p+1:3]))-colMeans(prob(drop(Q%*%dn[1:p]),dn[p+1:3])))/(2*h)})
 derr<-max(abs(numeric-G[,idx]));stopifnot(derr<1e-8)
 ans[[nm]]<-data.frame(model=nm,QR_vs_original_probability_error=err,analytic_vs_numeric_gradient_error=derr,normalization_error=max(abs(rowSums(p1)-1)))
 # Replace initial fit predictions with canonical Newton-polished predictions.
 write.csv(data.frame(source_row=f$data$source_row,ross_inc_id=f$data$ross_inc_id,observed=f$data$growth_potential,setNames(as.data.frame(p1),levels(f$data$growth_potential))),file.path(out,paste0(nm,'-fitted-probabilities.csv')),row.names=FALSE)
}
z<-do.call(rbind,ans);write.csv(z,file.path(out,'margins-validation.csv'),row.names=FALSE);print(z)
