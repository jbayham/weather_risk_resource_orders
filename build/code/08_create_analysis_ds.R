#This script generates the mob.ds (mobilization phase)



###############################################################
load("build/cache/temp_ds.Rdata")

#Dividing data into mob and demob phase for regression
#Cut data to only mobilization phase
# mob.ds <- inner_join(temp.ds %>%
#                        arrange(incident_number,report_date),
#                      temp.ds %>%
#                        group_by(incident_number) %>%
#                        summarize(max_personnel=max(total_personnel)),
#                      by=c("incident_number")) %>%
#   group_by(incident_number) %>%
#   mutate(sitnum=row_number(),
#          max_match=total_personnel==max_personnel,
#          max_match=ifelse(max_match,TRUE,NA),
#          max_match=ifelse(lag(max_match),FALSE,max_match),
#          max_match=ifelse(sitnum==1,TRUE,max_match)) %>%
#   fill(max_match) %>%
#   filter(max_match) %>%
#   ungroup() %>%
#   select(-total_personnel,-max_personnel,-merge.date)

#Alternative to calculating only mob phase
temp.ds <- temp.ds %>%
  group_by(incident_number) %>%
  mutate(sitnum = row_number()) %>%
  ungroup() %>%
  select(-total_personnel,-merge.date) 

#####################################################
#Creating additional variables
temp.ds <- temp.ds %>%  
  group_by(incident_number) %>%
  mutate(area = area/1000, 
         L1.area=lag(area),                #Lagging controls
         growth = (area - lag(area)),
         growth = ifelse(sitnum==1,area,growth),
         L1.growth = lag(growth),
         L1.evac = lag(evac),
         L1.evac = ifelse(sitnum==1,evac,L1.evac),
         doy_cos=cos(yday(report_date)),
         year=as.factor(year(fod_discovery_date)),
         time_since_disco=as.numeric(report_date-date(fod_discovery_date))) %>%
  ungroup() %>%
  filter(growth>=0)


##############
#Figure showing outliers
temp.ds %>%
  select(BI=L1.bi,
         ERC=L1.erc,
         Precipitation=L1.prcp,
         Humidity=L1.rmin,
         Temperature=L1.tmax,
         Wind=L1.wind,
         `Fire Growth`=growth,
         lag_growth=L1.growth) %>%
  #rename_all(~str_replace_all(.,"L1.","")) %>%
  gather(key="variable",value = "value") %>%
  bind_cols(.,
            temp.ds %>%
              select(BI=L1.bi,
                     ERC=L1.erc,
                     Precipitation=L1.prcp,
                     Humidity=L1.rmin,
                     Temperature=L1.tmax,
                     Wind=L1.wind,
                     `Fire Growth`=growth,
                     lag_growth=L1.growth) %>%
              #rename_all(~str_replace_all(.,"L1.","")) %>%
              transmute_all(isnt_out_z) %>%
              gather(key="Var2",value = "out") %>%
              select(-Var2)
            ) %>% 
  filter(value>0 & value<100 & variable!="lag_growth") %>%
  ggplot(aes(x=value,fill=out)) +
  geom_histogram() +
  facet_wrap(~variable,scales = "free") +
  theme_bw() +
  ylab("") +
  xlab("") +
  theme(legend.position = "none")
  
ggsave(filename = "report/figures/outliers.png")

##############

#Removing outliers and nonwestern gaccs
temp.ds <- temp.ds %>%
  select(L0.bi,L0.erc,L0.prcp,L0.rmin,L0.tmax,L0.wind,growth) %>%
  rename_all(~str_replace_all(.,"L0.","")) %>%
  transmute_all(isnt_out_z) %>%
  bind_cols(temp.ds,.) %>%
  filter_if(~all(is.logical(.)),all_vars(.)) %>%
  select(-bi:-wind,-growth1) %>%
  filter(gacc %in% c("SW","SO","NO","EB","WB","RM","NR","NW")) %>%
  mutate_if(is.factor,droplevels)


#Write out for stata
gp.ds <- temp.ds %>%
  select(ross_inc_id,growth_potential,starts_with("L0."),year,
         area,terrain,doy_cos,cause_descr,gacc,starts_with("PC")) %>%
  rename_all(~str_replace_all(.,"L0.","")) 

write_dta(gp.ds,path = "analysis/inputs/02_gp_ds_stata.dta")



#Converting and recoding categorical variables
temp.ds <- temp.ds %>%
  mutate_at(vars(contains("sfwp")),as.factor) %>%
  mutate_at(vars(pl_national,pl_region),as.factor) %>%
  mutate_at(vars(pl_national,pl_region),
            ~recode_factor(.,`1`="Low",`2`="Low",`3`="Medium",`4`="High",`5`="High")) %>%
  mutate_at(vars(pl_national,pl_region),
            ~relevel(.,ref = "Medium")) %>%
  mutate_if(is.character,as.factor) %>%  #character to factor
  mutate(growth_potential = factor(growth_potential,levels=c("Low","Medium","High","Extreme")),
         growth_potential = recode_factor(growth_potential,Extreme="High"),
         growth_potential = relevel(growth_potential,ref = "Medium"),
         terrain = recode_factor(terrain,Extreme="High"),
         terrain = relevel(terrain,ref="Medium")) 


##############################################################
#Constructing dataset for growth regression
growth.ds <- temp.ds %>%
  filter(growth>0 & p_contain<100) #Removing observations without growth 

save(growth.ds,file = "analysis/inputs/01_growth.Rdata")



##############################################################
#Constructing dataset for orders regression
orders.ds <- temp.ds %>%
  filter(growth>0 & L1.growth>0 & p_contain<100) #Removing observations without growth 

save(orders.ds,file = "analysis/inputs/03_orders.Rdata")


#Summary stat table for the gp data until migrate from stata
for.summary <- gp.ds %>% 
  select(growth_potential,terrain,area,
         gacc,sfwp,bi,erc,prcp,rmin,tmax,wind) 

sum.stat <- my_skim(for.summary) 
sum.stat %>% add_row(skim_type=data_rows(sum.stat)) %>% write_csv("report/tables/need_formatting/02_summary.csv")



#######################################################################
#Export ic_names for text cleanup in openrefine

# temp.ds %>%
#   mutate(ic_name=str_to_lower(ic_name)) %>%
#   select(ross_inc_id,sitnum,time_since_disco,ic_name) %>%
#   arrange(ic_name) %>%
#   write_csv(path = "data/ic_names_to_refine.csv")


#Remerge cleaned ic_names
# temp.ds <- temp.ds %>%
#   select(-ic_name) %>%
#   left_join(.,
#             read_csv("data/ic_names-csv.csv") %>% select(-time_since_disco)) %>%
#   arrange(incident_number,sitnum) %>%
#   group_by(incident_number,sitnum) %>%
#   fill(ic_name) %>%
#   ungroup() %>%
#   mutate(ic_name=ifelse(is.na(ic_name),"other",ic_name))

#########################################################################

