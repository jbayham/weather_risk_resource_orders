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
##########################################
#Function to download the project data (on first run, google should prompt you to login with credentials)
#if data folder doesn't exist, build data
#get_data("url")


folder.setup()


