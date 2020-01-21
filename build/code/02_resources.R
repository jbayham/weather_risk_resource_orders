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


resources <- resources %>%
  group_by(im_incident_number,im_report_date,im_hour) %>%
  summarise(total_personnel=sum(total_personnel,na.rm = T))


#Clean up data frames
rm(list=c("res.1999","res.2002"))

##########################################
print("Caching resources.Rdata")

save(resources,file = "build/cache/resources.Rdata")

close(dun.jolly)



  
  

