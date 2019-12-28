#This script links the weather to resource orders via our two-step model

################################################
#Load necessary data from growth potential regression and resource orders

load("analysis/cache/results_growth.Rdata")
load("analysis/cache/results_resource_orders.Rdata")
load("analysis/inputs/03_orders.Rdata")


###############################################
#First, relate weather to growth potential then through to total resources

temp.df <- orders.ds[-results.lm[[1]]$obsRemoved,]
pred.df <- model.matrix(all.resources[[2]]$fml,
                        data = temp.df) %>% 
  as_tibble() %>%
  select(-one_of("(Intercept)")) %>%
  summarise_all(mean) %>%
  mutate(growth_potentialHigh=0,
         growth_potentialLow=0) 

esttable(all.resources)
coef.table <- all.resources[[2]]$coeftable


mean(fixef(all.resources[[2]])$incident_number) + sum(coef.table$Estimate*pred.df[1,])

gp.high <- seq(from=.1,to=.35,length.out = 20)
x.df <- pred.df %>% 
  slice(rep(1:n(), each = length(gp.high))) %>%
  mutate(growth_potentialHigh=gp.high)

#Vector of mean resourced ordered
as.matrix(x.df)%*%coef.table$Estimate + mean(fixef(all.resources[[2]])$incident_number)

