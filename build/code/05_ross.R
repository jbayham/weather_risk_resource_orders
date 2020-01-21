#This script reads in the ROSS data that Erin compiled.  This data
#contains resource orders and assignments by day.

#Reading in data, creating requested as sum of filled and utf, then converting from long to wide format
ross <- read_csv(file="build/inputs/ROSSCountsForICS209Fires.csv") %>%
  mutate(requested=filled+utf) %>%
  select(-filled,-utf,-on_incident) %>%
  mutate(resource=str_replace_all(resource," |-","_"),
         resource=ifelse(resource=="T1_Airtanker","VLAT",resource),
         resource=ifelse(resource=="Fixed_Wing_Aircraft","T2_4_Airtanker",resource),
         resource=ifelse(resource=="T3_Helicopters","Helicopters",resource),
         resource=ifelse(resource=="T2_Helicopters","Helicopters",resource),
         resource=ifelse(resource=="T1_Helicopters","Helicopters",resource),
         resource=ifelse(resource=="Type_2_IA_Crews","Type_2_Crews",resource),
         date=mdy(date)) %>%
  group_by(rossid,date,resource) %>%
  summarize(requested=sum(requested,na.rm = T)) %>%
  ungroup() %>%
  spread(key = resource,value = requested)


print("Caching ross.Rdata")
save(ross,file = "build/cache/ross.Rdata")
