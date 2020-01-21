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


for.summary <- orders.ds[-results.lm[[1]]$obsRemoved,] %>% 
  select(Wildland_Engines,Structure_Engines,Dozers,Type_1_Crews,Type_2_Crews,
         VLAT,T2_4_Airtanker,Helicopters,
         growth,growth_potential,terrain,L1.evac,evac_potential,L1.area,
         year,gacc,
         L0.sfwp,L0.bi,L0.erc,L0.prcp,L0.rmin,L0.tmax,L0.wind) %>%
  mutate_at(vars(L1.evac,evac_potential),~factor(.,labels = c("No","Yes")))

sum.stat <- my_skim(for.summary) 
sum.stat %>% add_row(skim_type=data_rows(sum.stat)) %>% write_csv("report/tables/need_formatting/03_summary.csv")
