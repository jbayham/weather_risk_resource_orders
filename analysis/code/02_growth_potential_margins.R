# Counterfactual means and fire-clustered delta-method intervals.
library(ggplot2)
fits <- readRDS(file.path(out, "ordered-logit-polished.rds"))
levels_y<-c('Low','Medium','High','Extreme')
marginal <- function(a,var,vals) {
 p<-ncol(a$X);B<-a$A[1:p,1:p];mu<-colMeans(a$X);par<-a$theta_q
 ans<-list();i<-0
 for(v in vals){
  new<-a$data
  if(is.factor(new[[var]]))new[[var]]<-factor(v,levels=levels(new[[var]])) else new[[var]]<-v
  X<-model.matrix(a$formula,new)[,-1,drop=F];Q<-sweep(X,2,mu)%*%B
  eta<-drop(Q%*%par[1:p]);z<-par[p+1:3]
  F<-cbind(0,sapply(z,function(t)plogis(t-eta)),1);den<-cbind(0,sapply(z,function(t)dlogis(t-eta)),0)
  for(j in 1:4){
   probability<-F[,j+1]-F[,j]
   grad<-c(colMeans(Q*(den[,j]-den[,j+1])),rep(0,3))
   if(j<=3)grad[p+j]<-mean(den[,j+1]);if(j>=2)grad[p+j-1]<--mean(den[,j])
   se<-sqrt(drop(t(grad)%*%a$vcov_q%*%grad));est<-mean(probability);i<-i+1
   ans[[i]]<-data.frame(variable=var,value=v,outcome=levels_y[j],probability=est,se=se,lower=est-qnorm(.975)*se,upper=est+qnorm(.975)*se)
  }
 }
 do.call(rbind,ans)
}
specs<-list(erc=list('ol_index',seq(0,100,10)),bi=list('ol_index',seq(0,100,10)),rmin=list('ol_raw',seq(0,50,5)),prcp=list('ol_raw',seq(0,10,1)),wind=list('ol_raw',seq(0,30,3)),tmax=list('ol_raw',seq(10,45,4)),sfwp=list('ol_sfwp',1:5))
tabs<-lapply(names(specs),function(v){sp<-specs[[v]];z<-marginal(fits[[sp[[1]]]],v,sp[[2]]);z$model<-sp[[1]];z})
z<-do.call(rbind,tabs);z$outcome<-factor(z$outcome,levels=levels_y)
write.csv(z,file.path(out,'margins.csv'),row.names=F)
labels<-c(erc='Energy Release Component',bi='Burning Index',rmin='Minimum Humidity (%)',prcp='Precipitation (mm)',wind='Wind (mph)',tmax='Maximum Temperature (C)',sfwp='Categorical Fire Behavior Index')
for(v in names(specs)){
 p<-ggplot(z[z$variable==v,],aes(value,probability,color=outcome,group=outcome))+geom_line(linewidth=.6)+geom_errorbar(aes(ymin=lower,ymax=upper),width=if(v=='sfwp') .1 else diff(range(specs[[v]][[2]]))*.008,linewidth=.4)+scale_color_manual(values=c('#00A9ED','#FF3E37','#51B33B','#FDB600'))+coord_cartesian(ylim=c(0,.85))+labs(x=labels[v],y='Average predicted probability',color=NULL)+theme_bw(base_size=13)+theme(legend.position='top')
 ggsave(file.path('report/figures',paste0('gp_',v,'_R.png')),p,width=7,height=4.5,dpi=180)
}
# Figure 4 companion with the two published panels.
z4<-z[z$variable %in% c('erc','rmin'),];z4$panel<-factor(z4$variable,levels=c('erc','rmin'),labels=c('Energy Release Component','Minimum Humidity (%)'))
p4<-ggplot(z4,aes(value,probability,color=outcome,group=outcome))+geom_line(linewidth=.6)+geom_errorbar(aes(ymin=lower,ymax=upper),width=.5,linewidth=.35)+facet_wrap(~panel,scales='free_x',nrow=1)+scale_color_manual(values=c('#00A9ED','#FF3E37','#51B33B','#FDB600'))+coord_cartesian(ylim=c(0,.85))+labs(x=NULL,y='Average predicted probability',color=NULL,title='Figure 4 reproduced in R',subtitle='Ordered logit; fire-clustered delta-method 95% intervals')+theme_bw(base_size=12)+theme(legend.position='top')
ggsave('report/figures/Figure4_R.png',p4,width=11,height=4.7,dpi=180)
# Verify probability normalization for every margins setting.
check<-aggregate(probability~variable+value,z,sum);stopifnot(max(abs(check$probability-1))<1e-12)
print(z[z$variable %in% c('erc','rmin') & z$value %in% c(0,50,100),])
