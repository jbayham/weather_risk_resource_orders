#This script compiles the dataset by either running the appropriate munge script
#or by loading a cached copy


#########################
#Load cached data if exists otherwise build data

load.or.build("incident.Rdata","01_incident.R")
load.or.build("resources.Rdata","02_resources.R")
load.or.build("environment.Rdata","03_environment.R")
load.or.build("weather.Rdata","04_weather.R")
load.or.build("ross.Rdata","05_ross.R")
load.or.build("preparedness.Rdata","06_preparedness.R")
source("build/code/07_create_temp_ds.R")
source("build/code/08_create_analysis_ds.R")





