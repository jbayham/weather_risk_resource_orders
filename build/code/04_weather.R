#This script reads in the wui conditions contained in Chris Dunn's Access DB files 
#and prepares the data for merging.

########################
#Connecting to the access DB via ODBC
dun.jolly <- odbcDriverConnect(str_c("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=",
                                     "build/inputs/ICS_209_99_13_COMBINED_FOD_4CD_JollyWx.accdb"))
dun.ui <- odbcDriverConnect(str_c("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=",
                                  "build/inputs/ICS_209_99_13_COMBINED_FOD_4CD_UofIWx.accdb"))

##################
#Weather: Chris constructed these variables for a lag analysis so values exist 
#for every day of the year.  Most fires begin and end in the same year.  The files
#with the _end suffix end in the following year so need to consider this for merge.

#Jolly data
##Start
Jolly.bi <- sqlQuery(dun.jolly,
                     "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM Jolly_BI_start",
                     stringsAsFactors=F) %>% 
  as_tibble() 

Jolly.bi.pct <- sqlQuery(dun.jolly,
                         "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM Jolly_BI_pct_start",
                         stringsAsFactors=F) %>% 
  as_tibble() 

Jolly.erc <- sqlQuery(dun.jolly,
                      "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM Jolly_ERC_start",
                      stringsAsFactors=F) %>% 
  as_tibble() 

Jolly.erc.pct <- sqlQuery(dun.jolly,
                          "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM Jolly_ERC_pct_start",
                          stringsAsFactors=F) %>% 
  as_tibble() 

Jolly.sfwp <- sqlQuery(dun.jolly,
                       "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM Jolly_sfwp_start",
                       stringsAsFactors=F) %>% 
  as_tibble() 



##End
Jolly.bi.end <- sqlQuery(dun.jolly,
                         "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM Jolly_BI_end",
                         stringsAsFactors=F) %>% 
  as_tibble() %>%
  mutate(JULIAN_DATE=JULIAN_DATE+366)

Jolly.bi.end.pct <- sqlQuery(dun.jolly,
                             "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM Jolly_BI_pct_end",
                             stringsAsFactors=F) %>% 
  as_tibble() %>%
  mutate(JULIAN_DATE=JULIAN_DATE+366)

Jolly.erc.end <- sqlQuery(dun.jolly,
                          "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM Jolly_ERC_end",
                          stringsAsFactors=F) %>% 
  as_tibble() %>%
  mutate(JULIAN_DATE=JULIAN_DATE+366)

Jolly.erc.end.pct <- sqlQuery(dun.jolly,
                              "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM Jolly_ERC_pct_end",
                              stringsAsFactors=F) %>% 
  as_tibble() %>%
  mutate(JULIAN_DATE=JULIAN_DATE+366)

Jolly.sfwp.end <- sqlQuery(dun.jolly,
                           "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM Jolly_sfwp_end",
                           stringsAsFactors=F) %>% 
  as_tibble() %>%
  mutate(JULIAN_DATE=JULIAN_DATE+366)

close(dun.jolly)

#UofI data
##Start
ui.prcp <- sqlQuery(dun.ui,
                    "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM UofI_PRCP_start",
                    stringsAsFactors=F) %>% 
  as_tibble() 

ui.rmin <- sqlQuery(dun.ui,
                    "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM UofI_RMIN_start",
                    stringsAsFactors=F) %>% 
  as_tibble() 

ui.tmax <- sqlQuery(dun.ui,
                    "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM UofI_TMAX_start",
                    stringsAsFactors=F) %>% 
  as_tibble() 

ui.wind <- sqlQuery(dun.ui,
                    "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM UofI_WINDSPEED_start",
                    stringsAsFactors=F) %>% 
  as_tibble() 

#End
ui.prcp.end <- sqlQuery(dun.ui,
                        "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM UofI_PRCP_end",
                        stringsAsFactors=F) %>% 
  as_tibble() %>%
  mutate(JULIAN_DATE=JULIAN_DATE+366)

ui.rmin.end <- sqlQuery(dun.ui,
                        "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM UofI_RMIN_end",
                        stringsAsFactors=F) %>% 
  as_tibble() %>%
  mutate(JULIAN_DATE=JULIAN_DATE+366)

ui.tmax.end <- sqlQuery(dun.ui,
                        "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM UofI_TMAX_end",
                        stringsAsFactors=F) %>% 
  as_tibble() %>%
  mutate(JULIAN_DATE=JULIAN_DATE+366)

ui.wind.end <- sqlQuery(dun.ui,
                        "SELECT INCIDENT_NUMBER, JULIAN_DATE, VALUE FROM UofI_WINDSPEED_end",
                        stringsAsFactors=F) %>% 
  as_tibble() %>%
  mutate(JULIAN_DATE=JULIAN_DATE+366)

close(dun.ui)

#combining weather
weather.start <- inner_join(Jolly.bi %>% rename_all(str_to_lower) %>% rename(bi=value),
                            Jolly.erc %>% rename_all(str_to_lower) %>% rename(erc=value),
                            by = c("incident_number", "julian_date")) 

weather.start <- inner_join(weather.start,
                            Jolly.sfwp %>% rename_all(str_to_lower) %>% rename(sfwp=value),
                            by = c("incident_number", "julian_date"))

weather.start <- inner_join(weather.start,
                            Jolly.bi.pct %>% rename_all(str_to_lower) %>% rename(bi_pct=value),
                            by = c("incident_number", "julian_date"))

weather.start <- inner_join(weather.start,
                            Jolly.erc.pct %>% rename_all(str_to_lower) %>% rename(erc_pct=value),
                            by = c("incident_number", "julian_date")) %>% 
  distinct(.keep_all = T)

weather.start <- inner_join(weather.start,
                            ui.prcp %>% rename_all(str_to_lower) %>% rename(prcp=value),
                            by = c("incident_number", "julian_date"))

weather.start <- inner_join(weather.start,
                            ui.rmin %>% rename_all(str_to_lower) %>% rename(rmin=value),
                            by = c("incident_number", "julian_date")) %>% 
  distinct(.keep_all = T)

weather.start <- inner_join(weather.start,
                            ui.tmax %>% rename_all(str_to_lower) %>% rename(tmax=value),
                            by = c("incident_number", "julian_date"))

weather.start <- inner_join(weather.start,
                            ui.wind %>% rename_all(str_to_lower) %>% rename(wind=value),
                            by = c("incident_number", "julian_date")) %>% 
  distinct(.keep_all = T)



####
weather.end <- inner_join(Jolly.bi.end %>% rename_all(str_to_lower) %>% rename(bi=value),
                          Jolly.erc.end %>% rename_all(str_to_lower) %>% rename(erc=value),
                          by = c("incident_number", "julian_date"))

weather.end <- inner_join(weather.end,
                          Jolly.sfwp.end %>% rename_all(str_to_lower) %>% rename(sfwp=value),
                          by = c("incident_number", "julian_date"))

weather.end <- inner_join(weather.end,
                          Jolly.bi.end.pct %>% rename_all(str_to_lower) %>% rename(bi_pct=value),
                          by = c("incident_number", "julian_date"))

weather.end <- inner_join(weather.end,
                          Jolly.erc.end.pct %>% rename_all(str_to_lower) %>% rename(erc_pct=value),
                          by = c("incident_number", "julian_date"))

weather.end <- inner_join(weather.end,
                          ui.prcp.end %>% rename_all(str_to_lower) %>% rename(prcp=value),
                          by = c("incident_number", "julian_date"))

weather.end <- inner_join(weather.end,
                          ui.rmin.end %>% rename_all(str_to_lower) %>% rename(rmin=value),
                          by = c("incident_number", "julian_date"))

weather.end <- inner_join(weather.end,
                          ui.tmax.end %>% rename_all(str_to_lower) %>% rename(tmax=value),
                          by = c("incident_number", "julian_date"))

weather.end <- inner_join(weather.end,
                          ui.wind.end %>% rename_all(str_to_lower) %>% rename(wind=value),
                          by = c("incident_number", "julian_date")) %>% 
  distinct(.keep_all = T)

#appending weather obs in the end year to the main fire weather dataframe
weather <- bind_rows(weather.start,weather.end) %>% 
  arrange(incident_number,julian_date)

#unit coversions
weather <- weather %>%
  mutate(tmax=tmax-273.15,   #Temp Kelvin to Celsius
         wind=wind*2.237)    #m/s to mph

#Replace julian date with dates using start year and lubridate
weather <- inner_join(weather,
                      incident %>% 
                        dplyr::select(ics_209_incident_number,fire_year) %>%
                        rename(incident_number=ics_209_incident_number) %>%
                        mutate(fire_year=dmy(str_c("01-01-",fire_year))) %>%
                        distinct(incident_number,.keep_all = T),
                      by = "incident_number") %>%
  distinct(.keep_all = T)


weather <- weather %>%
  mutate(report_date=fire_year+days(julian_date-1))



##########################################
#Clean up data frames
rm(list=c(objects()[str_detect(objects(),"Jolly")],
          objects()[str_detect(objects(),"ui")],
          "weather.start","weather.end"))



##########################################
print("Caching weather.Rdata")
save(weather,file = "build/cache/weather.Rdata")


