#This script generates the figure used in the reviewer comments


#load base data 
load("analysis/inputs/01_growth.Rdata")
#load("E:/git_projects/weather_wildfire_suppression/analysis/inputs/03_orders.Rdata")

#Tabulate growth potential and evac potential
#tab_dist <- table(growth.ds$growth_potential,growth.ds$evac_potential)
tab_dist <- table(orders.ds$growth_potential,orders.ds$evac_potential)
tab_dist <- tab_dist[c(3,1,2),]
dimnames(tab_dist) <- list(c("Low","Medium","High"),
                           c("No","Yes"))

#plot data
plot(tab_dist,
     main = "",
     xlab = "Growth Potential",
     ylab = "Evacuation Potential")
