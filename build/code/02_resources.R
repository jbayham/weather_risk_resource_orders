#This script reads in the wui conditions contained in Chris Dunn's Access DB files 
#and prepares the data for merging.

########################
#Connecting to the access DB via ODBC
dun.jolly <- odbcDriverConnect(str_c("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=",
                                     "build/inputs/ICS_209_99_13_COMBINED_FOD_4CD_JollyWx.accdb"))

##########################
#Resources
res.1999 <- sqlQuery(dun.jolly,
                     "SELECT * FROM IMSR_INCIDENT_RESOURCES_1999_2002",
                     stringsAsFactors=F) %>% 
  as_tibble() %>% 
  rename_all(str_to_lower)

res.2002 <- sqlQuery(dun.jolly,
                     "SELECT * FROM IMSR_IMSR_209_INCIDENT_RESOURCES_2001_2013",
                     stringsAsFactors=F) %>% 
  as_tibble() %>% 
  rename_all(str_to_lower)

resources <- full_join(res.2002,
                      res.1999 %>% 
                        rename(im_report_date=ii_repdate,
                               im_incident_number=ii_event_id) %>%
                        select(-ag_aid_descr),
                      by=c("im_incident_number","im_report_date","ag_aid"))

#Merging incident and resources data (aggregating resources across agency)
# resources <- resources %>%
#   group_by(im_incident_number,im_report_date,im_hour) %>%
#   summarise_at(.vars = vars(sr_crew_1:ovhd),.funs = funs(sum,sum(.,na.rm = T)))

####
#It is informative to see a regression of number of personnel per resource in data
# reg.list <- resources %>% ungroup() %>% select(sr_crew_1_sum:camp_crew_sum) %>% names()
# personnel <- plm(as.formula(str_c("total_personnel_sum ~ ",str_c(reg.list,collapse = " + "))),
#                  data = res.merge %>% ungroup() %>% group_by(im_incident_number) %>% mutate(sitnum=row_number()),
#                  model = "within",
#                  index = c("im_incident_number","sitnum"))
# 
# summary(personnel, vcoc=vcovHC)

####
#combining strike teams and single resources; also combining similar resources
# resources <- resources %>%
#   mutate(crew1=sr_crew_1_sum+(27/18)*st_crew_1_sum, #27 personnel in a strike team vs 18 in hotshot crew or Fed type 2
#          crew1=ifelse(crw1_sum>0 & crew1==0,crw1_sum,crew1),
#          crew2=sr_crew_2_sum+(27/18)*st_crew_2_sum,
#          crew2=ifelse(crw2_sum>0 & crew2==0,crw2_sum,crew2),
#          helicopter1=ifelse(hel1_sum>0 & sr_helicopter_1_sum==0,hel1_sum,sr_helicopter_1_sum),
#          helicopter2=ifelse(hel2_sum>0 & sr_helicopter_2_sum==0,hel2_sum,sr_helicopter_2_sum),
#          helicopter3=ifelse(hel3_sum>0 & sr_helicopter_3_sum==0,hel3_sum,sr_helicopter_3_sum),
#          helicopter_other=helicopter_tanker_sum + usar_helicopter_sum,
#          engines=sr_engines_sum+5*st_engines_sum + truck_companies_sum, #5 engines to a strike team
#          engines=ifelse(engs_sum>0 & engines==0,engs_sum,engines),
#          water_tender=sr_water_tender_sum,
#          dozer=sr_dozer_sum + 2*st_dozer_sum + bombardier_sum + tractor_plow_1_sum + tractor_plow_2_sum + tractor_plow_3_sum + tractor_plow_4_sum, #2 dozers to a strike team
#          aircraft=c215_sum + c415_sum + fixed_wing_sum,
#          total_personnel=total_personnel_sum) %>% 
#   select(im_incident_number,im_report_date,im_hour,crew1:total_personnel)


resources <- resources %>%
  group_by(im_incident_number,im_report_date,im_hour) %>%
  summarise(total_personnel=sum(total_personnel,na.rm = T))


#Clean up data frames
rm(list=c("res.1999","res.2002"))

##########################################
print("Caching resources.Rdata")

save(resources,file = "build/cache/resources.Rdata")

close(dun.jolly)



  
  

