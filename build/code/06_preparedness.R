#This script reads in the preparedness level data collected by Erin
#PL is reported in each GACC by sheet



#Doing all but great basin region because it has two subareas
pl <- map(c("National","AK","EA","ONCC","NR","NW","RM","OSCC","SA","SW"),
               function(x){
                 read_excel("build/inputs/2007-2018_PLs_by_Erin.xlsx",sheet = x) %>%
                   select(Date,PL) %>%
                   rename_all(str_to_lower) %>%
                   mutate(gacc=x,
                          date=as_date(date))
               }) %>%
  bind_rows() %>%
  bind_rows(.,
            read_excel("build/inputs/2007-2018_PLs_by_Erin.xlsx",sheet = "GB") %>%
              select(Date,PL,gacc=Area) %>%
              rename_all(str_to_lower) %>%
              mutate(gacc=dplyr::recode(gacc,Eastern="EB",Western="WB"),
                     date=as_date(date)) )

#Recoding gacc names to match ics-209 format
pl <- pl %>%
  mutate(gacc=dplyr::recode(gacc,
                            ONCC="NO",
                            OSCC="SO"))

#################################
print("Caching preparedness_level.Rdata")
save(pl,file = "build/cache/preparedness_level.Rdata")


