#This script reads in the static environmental conditions contained in Chris Dunn's Access DB files 
#and prepares the data for merging.


########################
#Connecting to the access DB via ODBC
dun.jolly <- odbcDriverConnect(str_c("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=",
                                     "build/inputs/ICS_209_99_13_COMBINED_FOD_4CD_JollyWx.accdb"))

###############################
#Topography
topo <- sqlQuery(dun.jolly,
                 "SELECT * FROM Topography_2km",
                 stringsAsFactors=F) %>% 
  as_tibble() %>% 
  rename_all(str_to_lower) %>% 
  select(-id)

#vegetation
vegetation <- sqlQuery(dun.jolly,
                       "SELECT * 
                        FROM NLCD2001_2km_Area nlcd INNER JOIN EVT_subclass_2km_area evt
                        ON (nlcd.INCIDENT_NUMBER = evt.INCIDENT_NUMBER)",
                       stringsAsFactors=F) %>% 
  as_tibble()  %>% 
  rename_all(str_to_lower) %>%
  select(-one_of("id","id.1","incident_number.1"))

##########################################
print("Caching topo and vegetation dataframes in environment.Rdata")
save(list=c("topo","vegetation"),file = "build/cache/environment.Rdata")

close(dun.jolly)
