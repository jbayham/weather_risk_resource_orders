#Creating map of fire locations


#load base data 
load("analysis/inputs/01_growth.Rdata")
load("build/cache/incident.Rdata")

#Read in ross IMT data
imt <- read_csv("analysis/inputs/IncIDsPlusComplexity.csv") %>%
  rename_all(str_to_lower)

to.map <- growth.ds %>%
  arrange(ross_inc_id,sitnum) %>%
  dummy_cols(select_columns = "growth_potential") %>%
  group_by(ross_inc_id) %>%
  summarize(lat=first(fod_latitude),
            lon=first(fod_longitude),
            size=last(area),
            year=first(year),
            records=n(),
            gp_low=sum(growth_potential_Low,na.rm = T),
            gp_med=sum(growth_potential_Medium,na.rm = T),
            gp_high=sum(growth_potential_High,na.rm = T)) %>%
  mutate_at(vars(starts_with("gp_")),~str_c(round(./records*100,digits = 0),"%")) %>%
  ungroup() %>%
  inner_join(.,
             incident %>% select(ross_inc_id,fod_fire_name) %>% mutate(fod_fire_name=str_to_title(fod_fire_name)) %>% distinct(ross_inc_id,.keep_all=T),
             by="ross_inc_id") %>%
  inner_join(.,
             imt,
             by=c("ross_inc_id"="incid")) %>%
  #mutate(finalmaxcomplexity=factor(finalmaxcomplexity,labels = c("Most Complex"," "," "," ","Least Complex"))) %>%
  drop_na() %>%
  st_as_sf(coords=c("lon","lat")) %>%
  st_set_crs(4326) 

to.map.table <- to.map %>%
  st_set_geometry(NULL) %>%
  mutate(size=str_c(round(size*1000,digits = 0)," ac")) %>%
  select(`Fire Name`=fod_fire_name,
         `Year`=year,
         `Fire Size`=size,
         `209 Record Count`=records,
         `Growth Potential: Low`=gp_low,
         `Growth Potential: Medium`=gp_med,
         `Growth Potential: High`=gp_high,
         `Max Complexity`=finalmaxcomplexity
         )
  


#Using leaflet

marker.pal <- colorFactor(palette = "YlOrRd",to.map$finalmaxcomplexity,reverse = T)

m <- leaflet(to.map) %>% 
  addProviderTiles(providers$Stamen.Terrain,group = "Terrain") %>%
  addProviderTiles(providers$NASAGIBS.ViirsEarthAtNight2012, group = "Night Lights") %>%
  addCircleMarkers(color = ~marker.pal(finalmaxcomplexity),
                   fillOpacity = 0.7,
                   stroke = FALSE,
                   radius = ~(6 - finalmaxcomplexity +2),
                   clusterOptions = markerClusterOptions(disableClusteringAtZoom=6),
                   #label = ~fod_fire_name,
                   popup = popupTable(to.map.table,row.numbers = F, feature.id = F),
                   group = "Fires") %>%
  addLegend(pal = marker.pal, 
            values = ~finalmaxcomplexity, 
            opacity = 0.7, 
            #labels = c("Most Complex","","","","Least Complex"),
            title = "Complexity",
            position = "bottomright") %>%
  addLayersControl(
    baseGroups = c("Terrain","Night Lights"),
    overlayGroups = c("Fires"),
    options = layersControlOptions(collapsed = FALSE)
  ) 
  
saveWidget(m,str_c(getwd(),"/report/figures/fire_weather_map.html"))
save(m,file = "analysis/cache/map_for_image.Rdata")

#preview and screen shot
# leaflet(to.map,options = leafletOptions(zoomControl = FALSE)) %>% 
#   addProviderTiles(providers$Stamen.Terrain,group = "Terrain") %>%
#   #addProviderTiles(providers$NASAGIBS.ViirsEarthAtNight2012, group = "Night Lights") %>%
#   addCircleMarkers(color = ~marker.pal(finalmaxcomplexity),
#                    fillOpacity = 0.7,
#                    stroke = FALSE,
#                    radius = ~(6 - finalmaxcomplexity +2),
#                    clusterOptions = markerClusterOptions(disableClusteringAtZoom=5),
#                    #label = ~fod_fire_name,
#                    popup = popupTable(to.map.table,row.numbers = F, feature.id = F),
#                    group = "Fires") %>%
#   addLegend(pal = marker.pal, 
#             values = ~finalmaxcomplexity, 
#             opacity = 0.7, 
#             #labels = c("Most Complex","","","","Least Complex"),
#             title = "Complexity",
#             position = "bottomleft") %>%
#   addLayersControl(
#     baseGroups = c("Terrain","Night Lights"),
#     overlayGroups = c("Fires"),
#     options = layersControlOptions(collapsed = FALSE)
#   ) 
  




