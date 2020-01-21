#This script generates the figure used in the reviewer comments


#load base data 
load("analysis/inputs/01_growth.Rdata")

#Tabulate growth potential and evac potential
tab_dist <- table(orders.ds$growth_potential,orders.ds$evac_potential)
tab_dist <- tab_dist[c(3,1,2),]
dimnames(tab_dist) <- list(c("Low","Medium","High"),
                           c("No","Yes"))

#plot data
plot(tab_dist,
     main = "",
     xlab = "Growth Potential",
     ylab = "Evacuation Potential")
