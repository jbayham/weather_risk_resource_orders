#This script reads in the wui conditions contained in Chris Dunn's Access DB files 
#and prepares the data for merging.

########################
#Connecting to the access DB via ODBC
dun.jolly <- odbcDriverConnect(str_c("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=",
                                     "build/inputs/ICS_209_99_13_COMBINED_FOD_4CD_JollyWx.accdb"))

##########################
#Incident table
incident <- sqlQuery(dun.jolly,
                     "SELECT *
                     FROM FOD_ROSS_INCIDENT_JOIN_NO_CMPLXS_EDITED_20150728_MISMATCHES_RMVD fod INNER JOIN
                     1999_2013_IMSR_209_INCIDENTS imsr 
                     ON (fod.ICS_209_INCIDENT_NUMBER = imsr.INCIDENT_NUMBER);",
                     stringsAsFactors=F) %>% 
  as_tibble() %>% 
  rename_all(str_to_lower)






##########################################
print("Caching incident.Rdata")
save(incident,file = "build/cache/incident.Rdata")

close(dun.jolly)
