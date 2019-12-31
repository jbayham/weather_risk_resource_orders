#This script estimates a model of realized fire growth on weather and other controls


load("analysis/inputs/01_growth.Rdata")


lag.var.list <- list(c("prcp","rmin","tmax","wind","bi","erc","sfwp"),
                     c("prcp","rmin","tmax","wind"),
                     c("bi","erc"),
                     c("sfwp"))
lag.length=c(str_c("L",c(1)))



###############################################################
#

output.growth <- map(lag.var.list,
    function(x){
      
      vars.cat <- expand.grid(lag.length,x) %>%
        mutate(out=str_c(Var1,".",Var2))
      
      rhs.vars <- c(vars.cat$out,
                    c("terrain","doy_cos*gacc","splines::ns(L1.area,df=3)",
                      "cause_descr",
                      "year",
                      str_c("PC",1:20))
      )
      
      model.formula <-
        formula(str_c("growth ~ ",
                      str_c(rhs.vars, collapse = " + ")))

      lm.model <- glm(model.formula,
                      data = growth.ds,
                      family = "quasipoisson")
      
      # lm.model <- lm(model.formula,
      #                 data = growth.ds)
      
      
      
      coeftest(lm.model,vcov=vcovCL(lm.model,cluster = growth.ds$ross_inc_id[-lm.model$na.action]))
      
      coeftest(lm.model,vcov=vcovCL(lm.model,cluster = growth.ds$ross_inc_id[-lm.model$na.action])) %>%
        tidy() %>%
        add_row(term="Effron R2", estimate=PseudoR2(lm.model, which = "Effron")) %>%
        write_csv(.,path = str_c("report/tables/need_formatting/01_growth_wx_",str_c(vars.cat$Var2,collapse = "_"),".csv"))
      
      to.map <- read_csv("report/wx_names.csv",col_names = T) %>%
        mutate(var=str_c("L1.",abbr)) %>%
        filter(abbr %in% vars.cat$Var2)
      
      pmap(list(var=to.map$var,
                name=to.map$name,
                file_name=to.map$abbr,
                xmin=to.map$xmin,
                xmax=to.map$xmax),
           function(var,name,file_name,xmin,xmax){
             png(
               str_c("report/figures/",file_name,".png"),
               width = 6,
               height = 4,
               units = "in",
               res = 300)
             
             cplot(lm.model,
                   x=var,
                   vcov = vcovCL(lm.model, cluster = growth.ds$ross_inc_id[-lm.model$na.action]),
                   ylim= c(0,3),
                   xlim = c(xmin,xmax),
                   xlab = name,
                   ylab = "Predicted Growth (1,000 ac)")
             
             dev.off()
           })
      return(lm.model)
    })

#Save raw results for simulation
save(output.growth,file = "analysis/cache/results_growth.Rdata")

# Summary Stats 
for.summary <- growth.ds[-output.growth[[1]]$na.action,] %>% 
  select(Wildland_Engines,Structure_Engines,Dozers,Type_1_Crews,Type_2_Crews,
         VLAT,T2_4_Airtanker,Helicopters,
         growth,growth_potential,terrain,L1.evac,evac_potential,L1.area,
         year,gacc,
         L0.sfwp,L0.bi,L0.erc,L0.prcp,L0.rmin,L0.tmax,L0.wind) %>%
  mutate_at(vars(L1.evac,evac_potential),~factor(.,labels = c("No","Yes")))




sum.stat <- my_skim(for.summary) 

sum.stat %>% add_row(skim_type=data_rows(sum.stat)) %>% write_csv("report/tables/need_formatting/01_summary.csv")



################################################################################
#Alternatively, margins::cplot outputs the data to use with ggplot (but not with nice rug to show data density)
# test %>%
#   mutate(for_hist=table(cut(lm.model$model$L1.bi,breaks = c(0,test$xvals)))) %>%
#   ggplot(., aes(x = xvals)) +
#   geom_ribbon(aes(ymin = lower, ymax = upper), fill = "gray70") +
#   geom_line(aes(y = yvals)) +
#   #xlab("Vehicle Weight (1000s of lbs)") +
#   #ylab("Average Marginal Effect of Rear Axle Ratio") +
#   #ggtitle("Predicting Automatic/Manual Transmission from Vehicle Characteristics") +
#   theme_bw()




