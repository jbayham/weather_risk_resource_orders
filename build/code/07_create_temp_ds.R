#This script joins the various datasets into a dataframe for analysis




###################################
#Merging incident and resources data (aggregating resources across agency)
base.data <- incident %>%
  ungroup() %>%
  #mutate(evac=ifelse(evacuation_in_progress=="Y" | potential=="Y",1,0)) %>%
  mutate(evac=ifelse(evacuation_in_progress=="Y",1,0),
         evac_potential=ifelse(potential=="Y",1,0)) %>%
  select(im_incident_number=ics_209_incident_number,
         im_report_date=report_date,
         im_hour=hour,
         ross_inc_id,
         # status,
         gacc,
         fod_latitude,
         fod_longitude,
         # imt_type_description,agency,
         strategy=`209_initial_strategy`,
         cause_descr,
         area,
         # fod_fire_size,
         fod_discovery_date,
         p_contain,
         # ross_max_team_type,
         # disco_to_cont,
         # disco_to_first_order,
         # disco_to_ia,
         # disco_to_last_ff_off,
         # `disco_to_last_ic/imt_off`,
         ic_name,
         growth_potential,
         terrain,
         evac_potential,
         evac) %>%
  inner_join(.,resources,by=c("im_incident_number","im_report_date","im_hour")) %>%
  rename(incident_number=im_incident_number,
         report_date=im_report_date) %>%
  mutate(report_date=date(report_date)) %>%
  arrange(incident_number,report_date,-im_hour) %>%
  distinct(incident_number,report_date,.keep_all = T) %>% #Consolidate multiple observations in a day by taking the last report of the day
  select(-im_hour)


################################
#Constructing time-varying variables
#########
#structures threatened, damaged, and destroyed
# tv.ds <- left_join(base.data,
#                    structures,
#                    by=c("incident_number","report_date")) 

#ross resources
tv.ds <- left_join(base.data,
                   ross,
                   by=c("ross_inc_id"="rossid","report_date"="date"))     


#Preparedness level
tv.ds <- 
  left_join(tv.ds,
            pl %>% rename(pl_region=pl),
            by=c("gacc"="gacc","report_date"="date")) %>%
  left_join(.,
            pl %>% rename(pl_national=pl) %>% dplyr::filter(gacc=="National") %>% select(-gacc),
            by=c("report_date"="date"))

##################################
#Constructing time-invariant variables
#########
#If adding more data, do so here before merging with lagged weather
#topographic information
ti.ds <- left_join(vegetation,
                   topo,
                   by="incident_number") %>% 
  distinct(incident_number,.keep_all = T)

###
#Old but may keep

#wui data
# ti.ds <- left_join(ti.ds,
#                    wui %>% select(-one_of("id")),
#                    by="incident_number") %>% distinct(incident_number,.keep_all = T)


#Reducing the dimensionality of static controls using PCA
# pca.wui <- prcomp(ti.ds %>% 
#                     select(wuidist:facehdendist) %>% 
#                     mutate_all(~ifelse(is.na(.),0,.)),
#                   center = TRUE,
#                   scale. = TRUE)
#summary(pca.wui) #79% of variation from first PC

#wui.controls <- as_tibble(pca.wui$x[summary(pca.wui)$importance[3,]<.8])

# pca.topo <- prcomp(ti.ds %>% 
#                      select(ha_nlcd_sub0:ruggedness) %>% 
#                      mutate_all(~ifelse(is.na(.),0,.)) %>% 
#                      select(which(apply(.,2,sum)!=0)),
#                    center = TRUE,
#                    scale. = TRUE)
# 
# topo.controls <- as_tibble(pca.topo$x[,summary(pca.topo)$importance[3,]<.8]) #setting threshold at 80% of variation from first PC
# 
# ti.controls <- bind_cols(wui.controls,topo.controls) %>%
#   rename_all(~str_c("PC",seq.int(1,dim(wui.controls)[2]+dim(topo.controls)[2]))) %>%
#   bind_cols(ti.ds %>% select(incident_number),.)


pca.topo <- prcomp(ti.ds %>% 
                     select(ha_nlcd_sub0:ruggedness) %>% 
                     mutate_all(~ifelse(is.na(.),0,.)) %>% 
                     select(which(apply(.,2,sum)!=0)),
                   center = TRUE,
                   scale. = TRUE)

topo.controls <- as_tibble(pca.topo$x[,summary(pca.topo)$importance[3,]<.8]) #setting threshold at 80% of variation from first PC

ti.controls <- topo.controls %>%
  rename_all(~str_c("PC",seq.int(1,dim(topo.controls)[2]))) %>%
  bind_cols(ti.ds %>% select(incident_number),.)


#########
#Combining time-invariant and time-varying variables
temp.ds <- left_join(tv.ds,
                     ti.controls,
                     by = "incident_number") %>%
  distinct(incident_number, report_date,.keep_all = T)



#######################
#Merging the weather variables for distributed lag model.  
#The strategy is to generate a temp incident dataset, lag the report date and join with weather data.

#Since weather is reported once a day and incidents and resources may be reported 
#more than once a day.  I will merge weather first to the report date then merge 
#resources including hour

weather.lag <- incident %>%
  distinct(ics_209_incident_number,report_date) %>%
  rename(incident_number=ics_209_incident_number) %>%
  mutate(report_date=date(report_date)) %>%
  arrange(incident_number,report_date)

#Lags
for(i in 0:1){
  weather.lag <- 
    inner_join(
      weather.lag %>%
        mutate(merge.date = report_date - i),
      weather %>%
        select(-one_of("julian_date", "fire_year")) %>%
        rename_at(.vars = vars(bi:wind),  ~ str_c("L", i, ".", .)),
      by = c("incident_number" = "incident_number", "merge.date" = "report_date")
    ) %>%
    distinct(incident_number,report_date,.keep_all = T)
}

#Leads
# for(i in 1:7){
#   weather.lag <- inner_join(weather.lag %>%
#                               mutate(merge.date= report_date + i),
#                             weather %>%
#                               select(-one_of("julian_date","fire_year")) %>%
#                               rename_at(.vars = vars(bi:wind),.funs = funs(str_c("F",i,".",.))),
#                             by=c("incident_number" = "incident_number","merge.date" = "report_date")) %>%
#     distinct(incident_number,report_date,.keep_all = T)
# }


####################################
#Creating analysis dataset
temp.ds <- inner_join(temp.ds,
                      weather.lag,
                      by = c("incident_number", "report_date")) %>%
  distinct(incident_number, report_date,.keep_all = T)


#Looking at dataset completeness
#rnoaa::vis_miss(temp.ds %>% select(incident_number:Dozers,pl_national,PC1))

#Filling down missing data from prior reports if available
temp.ds <- temp.ds %>%
  arrange(incident_number,report_date) %>%
  group_by(incident_number) %>%
  tidyr::fill(strategy,cause_descr,growth_potential,terrain,.direction="down") %>% 
  ungroup()


save(temp.ds,file = "build/cache/temp_ds.Rdata")



