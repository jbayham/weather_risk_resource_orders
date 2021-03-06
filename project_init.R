#This script initializes the project and should be run at the beginning of each
#session

#########################
#Load init functions
source("functions/init_functions.R")

#Loading and installing packages
init.pacs(c("tidyverse",      #shortcut to many useful packages (eg, dplyr, ggplot)
            "conflicted",     #resolves function conflict across packages
            "lubridate",      #working with dates
            "sf",             #for GIS
            "USAboundaries",  #easily access US maps in sf
            "leaflet",        #Interactive mapping
            "htmltools",      #additional html utilities
            "htmlwidgets",    #additional html utilities   
            "leafpop",        #easy tables in leaflet popup
            "fastDummies",    #tidy compatible dummy variables
            "googledrive",    #for accessing googledrive
            "RODBC",          #accessing MSAccess DB 
            "readxl",         #reading excel files
            "fixest",         #for FE estimation
            "margins",        #for margin plots like stata
            "lmtest",         #clustered se
            "sandwich",       #clustered se
            "broom",          #tidy a regression object
            "skimr",          #For summary stat tables
            "DescTools",      #For model fit calculations
            "haven",          #For export to stata
            "dotwhisker",     #visualize regression output
            "corrplot"        #generate correlation plots
))


#Setting package conflict preferences
conflict_prefer("select", "dplyr")
conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")
conflict_prefer("last", "dplyr")
conflict_prefer("between", "dplyr")

#Defining skimr function for summary stat tables
my_skim <- skim_with(numeric = sfl(mean=~mean(.,na.rm = T),
                                   sd=~sd(.,na.rm = T),
                                   min=~min(.,na.rm = T),
                                   max=~max(.,na.rm = T)), append = FALSE)

#########################
#Loading project helper functions (all scripts within folder)
run.script("functions")


##########################################


folder.setup()


if(length(dir("build/inputs"))==0){
  message("Request data from jbayham@colostate.edu")
}

