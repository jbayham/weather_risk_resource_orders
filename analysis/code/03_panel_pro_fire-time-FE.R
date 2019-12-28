#This script develops the model to test the hypotheses about
#whether resources are requested/dispatched proactively or 
#reactively.  


#Note that the R2 values from FE don't really tell us how well the FE estimation
#procedure accounts for variation in the data.  It tells us how well the
#included regressors explain variation that exists after the detrending.  Since
#we are running two way, there likely isn't alot of variation left to explain.

load("analysis/inputs/03_orders.Rdata")

orders.ds <- orders.ds %>%
  mutate(all_resources=Wildland_Engines + Structure_Engines + Dozers + Type_1_Crews + Type_2_Crews + 
         VLAT + T2_4_Airtanker + Helicopters)
################################################
#varying model specification
res.var <- "all_resources"  #"FixedWingAircraft_requested"

formula.input <- list(
  str_c(res.var," ~ ",
        str_c(c("growth_potential","L1.growth","terrain","doy_cos:gacc","splines::ns(L1.area,df=3)"),collapse = " + "),
        "|incident_number"),
  str_c(res.var," ~ ",
        str_c(c("growth_potential*evac_potential","L1.growth*L1.evac","terrain","doy_cos:gacc","splines::ns(L1.area,df=3)"),collapse = " + "),
        "|incident_number"),
  str_c(res.var," ~ ",
        str_c(c("growth_potential*evac_potential","L1.growth*L1.evac","terrain","doy_cos:gacc","splines::ns(L1.area,df=3)"),collapse = " + "),
        "|incident_number+time_since_disco"),
  str_c(res.var," ~ ",
        str_c(c("growth_potential*evac_potential","L1.growth*L1.evac","terrain","doy_cos:gacc","splines::ns(L1.area,df=3)"),collapse = " + "),
        "|incident_number+time_since_disco+ic_name")
)
#FE panel model
# mob.pdata <- orders.ds %>%
#   select(ross_inc_id,time_since_disco,Dozers:Wildland_Engines,one_of(rhs.vars[[1]]),L1.evac,evac_potential,pl_national) %>%
#   drop_na() %>%
#   distinct(ross_inc_id,time_since_disco,.keep_all = T) %>%
#   pdata.frame(.,index = c("ross_inc_id","time_since_disco"))

all.resources <- map(formula.input,
                 function(x){

                   model.formula <- formula(x)
                   
                   model.out <- feols(model.formula,
                                     data = orders.ds) 
                   

                   return(model.out)
                 })

esttable(all.resources,
         drop = "^doy|^spline|^terrain",
         signifCode = c(`***` = 0.01, 
                        `**`  = 0.05, 
                        `*` = 0.1),
         digits = 2) %>%
  rownames_to_column(var = "Variable") %>%
  write_csv(path="report/tables/need_formatting/03_growth_gp_all.csv")




################################################
#Panel regs
lhs.var.list <- orders.ds %>% 
  select(Wildland_Engines,Structure_Engines,Dozers,Type_1_Crews,Type_2_Crews,
         VLAT,T2_4_Airtanker,Helicopters) %>% 
  names(.) 

rhs.var <- c("growth_potential*evac_potential",
             "L1.growth*L1.evac",
             "terrain","doy_cos:gacc","splines::ns(L1.area,df=3)")



results.lm <- vector("list",length(lhs.var.list))
fe.time <- vector("list",length(lhs.var.list))
fe.id <- vector("list",length(lhs.var.list))
model.stats <- vector("list",length(lhs.var.list))
for(i in c(1:length(lhs.var.list))){
  lhs.var <- lhs.var.list[i]

  on.inc.formula <- formula(str_c(lhs.var," ~ ",
                                  str_c(rhs.var,collapse = " + "),"|incident_number") )
  
  results.lm[[i]] <- feols(on.inc.formula,
                   data = orders.ds)

  
  fe.id[[i]] <- fixef(results.lm[[i]])$incident_number %>%
    enframe() %>%
    rename(fire=name)  %>%
    mutate(var=lhs.var)
  
}


esttable(results.lm,
         drop = "^doy|^spline|^terrain",
         signifCode = c(`***` = 0.01, 
                        `**`  = 0.05, 
                        `*` = 0.1),
         digits = 2) %>%
  rownames_to_column(var = "Variable") %>%
  write_csv(path="report/tables/need_formatting/03_growth_gp_by_resource.csv")


save(results.lm,all.resources,file = "analysis/cache/results_resource_orders.Rdata")

#Render the Rmarkdown file
# rmarkdown::render(input = "report/Results.Rmd",
#                   output_file = "results_inter.html",
#                   output_format = "html_document")

for.summary <- orders.ds[-results.lm[[1]]$obsRemoved,] %>% 
  select(Wildland_Engines,Structure_Engines,Dozers,Type_1_Crews,Type_2_Crews,
         VLAT,T2_4_Airtanker,Helicopters,
         growth,growth_potential,terrain,L1.evac,evac_potential,L1.area,
         year,gacc,
         L0.sfwp,L0.bi,L0.erc,L0.prcp,L0.rmin,L0.tmax,L0.wind) %>%
  mutate_at(vars(L1.evac,evac_potential),~factor(.,labels = c("No","Yes")))

sum.stat <- my_skim(for.summary) 
sum.stat %>% add_row(skim_type=data_rows(sum.stat)) %>% write_csv("report/tables/need_formatting/03_summary.csv")
###############################################
# #Summary Stats
# #stargazer::stargazer(on.inc.fe$model)
# orders.ds %>% 
#   select(lhs.var.list,contains("threatened"),L1.evac_yes,
#          L0.bi,L0.erc,L0.sfwp,L0.prcp,L0.rmin,L0.tmax,L0.wind,growth) %>%
#   as.data.frame() %>%
#   stargazer::stargazer(.,
#                        type = "text")
# 
# #results quickout
# lhs=4
# stargazer::stargazer(results.lm[[2]],type = "text")
# stargazer::stargazer(results.lm[[lhs]],results.glm[[lhs]],
#                      type = "text")
# 
# 
# 
# for.spline <- orders.ds %>% 
#   select(y=T2_4Airtanker_requested,x=growth) %>%
#   drop_na() %>%
#   as.data.frame()
# 
# sp.out <- smooth.spline(y=for.spline$FixedWingAircraft_requested,
#               x=for.spline$L0.wind,
#               df=3)
# 
# plot(sp.out)
# 
# drsmooth::spline.plot(dosecolumn = "x",
#                       targetcolumn = "y",
#                       k=4,
#                       data_type = "continuous",
#                       data = for.spline)
# 
# summary()
# 
# results.df <- bind_rows(results) %>% 
#   left_join(.,
#             on.inc.fe$model %>%                #Means for effect comparison
#               select(matches("L0|threatened")) %>% 
#               summarize_all(~mean(.,na.rm=T)) %>%
#               gather(key="term",value="mean"),
#             by="term") %>%
#   mutate(estimate=ifelse(is.na(mean),estimate,estimate*mean),
#          std.error=ifelse(is.na(mean),std.error,std.error*mean),
#          statistic=estimate/std.error)
# 
# 
# #Generating the dotwhisker plot
# dwplot(results.df %>% filter(str_detect(model,"Structure")), 
#        style="dotwhisker",
#        by_2sd = F,
#        vline = geom_vline(xintercept = 0, colour = "grey60", linetype = 2)) + 
#   theme_bw() +
#   scale_x_continuous(limits = c(-1.5,1.5)) +
#   #ggtitle(g.title) +
#   xlab("Coef. Est.") +
#   ylab("")
# 
# 
# 
# 

##########################################
#Experimenting with visualizing splines.  Most of the code below is unecessary.
#It seems like with fixest, I need to generate a new dataframe with mean values
#for things I want to hold constant and let the variable of interest change.
# spo=splines::ns(mob.ds$L1.area[-fe.model.seq[[2]]$obsRemoved],df=3)
# head(predict(spo,mob.ds$L1.area[-fe.model.seq[[2]]$obsRemoved]))
# 
# coef(fe.model.seq[[2]])[str_which(names(coef(fe.model.seq[[2]])),"spline")]
# 
# spline.predict <- splines::ns(mob.ds$L1.area[-fe.model.seq[[2]]$obsRemoved],df=3)%*%coef(fe.model.seq[[2]])[str_which(names(coef(fe.model.seq[[2]])),"spline")] %>%
#   as.numeric()
# 
# 
# 
# 
# mob.ds[-fe.model.seq[[2]]$obsRemoved,] %>%
#   mutate(pred=predict(fe.model.seq[[2]])) %>%
#   ggplot(aes(y=pred,x=L1.growth,color=as.factor(L1.evac))) +
#   geom_smooth()
# 
# mob.ds[-fe.model.seq[[2]]$obsRemoved,] %>%
#   mutate(pred=predict(fe.model.seq[[2]])) %>%
#   ggplot(aes(y=pred,x=L1.area,color=as.factor(L1.evac))) +
#   # geom_point() +
#   geom_smooth() +
#   geom_rug() +
#   xlim(c(0,25)) +
#   ylim(c(1,2.5))
