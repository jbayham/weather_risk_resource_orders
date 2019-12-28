
# The effect of weather on resource ordering patterns during large wildland fires

Jude Bayham, Erin J. Belval, Matthew P. Thompson, David E. Calkin, Crystal S. Stonesifer, and Christopher Dunn 

Weather conditions are a well-known determinant of fire behavior. Yet, there is little empirical evidence on how incident commanders respond to observed or expected weather conditions. We compile a novel dataset on wildfire resource requests, weather conditions, and fire growth to investigate the extent to which incident commanders respond to realized or expected fire behavior and risks.  Our results suggest that incident commanders are forward-looking and respond to expected rather than recently observed fire behavior.  Moreover, the results vary by resource type, which has important implications for forecasting resource needs and costs.  

This repository contains the data and scripts to construct the dataset and run the analyses to generate figures and tables reported in the manuscript.

# To Do
- Host raw data
- Finish supplement
- Snapshot packages with packrat (https://www.joelnitta.com/post/packrat/packrat/)

********************************************

# Project and directory structure

This section describes the directory structure of the project.  The project is divided into two primary parts.  Part 1 builds the datasets to be used in the analysis phase.  Part 2 contains scripts to run the analysis and generate output (tables and figures).  Note that the dataset produced in Part 1 is written to the inputs directory in Part 2.

## Part 1: Build

- `inputs` directory contains the raw data that should not be modified or overwritten
- `cache` directory stores copies of data during intermediate steps in the preprocessing   
- `code` directory contains all scripts to read in and preprocess the data  

The code directory includes a make file (`00-build.R`) for the dataset build phase of the project.

## Part 2: Analysis

- `inputs` directory contains the dataset built in Part 1
- `cache` directory stores copies of data or results during analysis steps     
- `code` directory contains all scripts to read in and preprocess the data. Tables and figures are saved  to a subdirectory in the reports directory.  

The `functions` directory contains all functions specific to this analysis.  
The `report` directory contains the write up of the project.  It   
The `references` directory contains bib files for the project.

## Building the Project

The project root directory contains a file called `project_init.R` that initializes the project (installs/loads packages etc.).  You should run this file each time you open R to begin working on the project.  

*Note that all file references within project are relative to the root directory of the project.*

**********************
# Data

The data directory contains two MS Access DBs compiled by Chris Dunn.  The two datasets contain much of the same information but one contains Matt Jolly's weather data and the other contains gridMET weather data.  The excel file titled MetaData provides descriptions of the tables in the Access DBs.

Data sources:  

- U of I weather data is from the gridMet product (ABATZOGLOU Lab).  This is the source for the BI, ERC, precipitation, minimum humidity, maximum temperature, and wind.  Note that the BI and ERC are calculated (or calibrated) for fuel model G (http://www.climatologylab.org/gridmet.html).

## Build 

The build/code directory contains a series of numbered scripts.  These scripts should be run in order to reproduce the dataset.

- The script 00-build.R builds the dataset by either loading a cached copy or running the script to build each component.  

- The script 01-incident.R imports the 209 incident table from Dunn's DB.  This appears to be a subset of fires not in complexes and with more than three reports.

- The script 02-resources.R imports the resource tables from Dunn's DB.  The resource reporting appears to have changed in 2001 or 2002 so I append the tables together.  Pre-2002, strike teams and single resources are aggregated.  

- The script 03-read_in_environment.R imports the data from the topography tables and vegetation tables in Dunn's DB.  These are all of the time-invariant environmental controls used in subsequent models.

- The script 04-read_in_weather.R imports weather data from tables both Access DBs.  One of the DBs contains tables with BI (burning index), ERC (energy release component), and SFWP (severe fire weather potential).  The DB call UofI contains data on max temperature, minimum humidity, precipitation, and windspeed.

- The script 05-ross.R imports the ROSS data that Erin extracted.  The data contain daily requests, utfs, and assignments for the following resource types: VLAT, Type 1 Airtankers, Type 2-4 Airtankers, Fixed Wing Aircraft, Type 1 Helicopters, Type 2 Helicopters, Type 3 Helicopters, Dozers, Structure Engines, Wildland Engines, Type 1 Crews, Type 2 Crews, and Type 2IA Crews.  Several of these categories are collapsed for the analysis.

- The script 06-preparedness.R imports the daily national and GACC preparedness level data compiled by Erin.

- The script 07_create_temp_ds.R merges the individual components together and cahces an intermediate dataset called temp_ds.Rdata.  

- The script 08_create_analysis_ds.R creates datasets for each analysis: model of growth, model of growth potential, and model of resource orders.  This script also generates an outliers plot of weather and growth observations that are removed.  The script also contains code that outputs the list of IC names to Google Open Refine for text cleanup.  The names are remerged back with the dataset for use as fixed effect controls when modeling resource orders. 


******************************************
# Analysis

The analysis/code directory contains script to conduct analyses and produce figures and tables.  Intermediate outputs are cached to the analysis/cache directory.  

- The script 01_growth.R reads the cached dataset growth.Rdata runs the ananlysis of observed fire growth as a function of weather and other controls.  

- The script 02_growth_potential.do reads in a cached dataset 02_gp_ds_stata.dta and runs the ordered logit models and generates figures.  *Note that this analysis is conducted in Stata.*

- The script 03_orders_FE.R reads the 03_orders.Rdata dataset and runs the FE models of resource orders.

- The script 04_simulation.R illustrates how to use the model results together to understand the link between weather and resource orders.


******************************************
# Report

The report directory contains the manuscript and supporting documents such as tables and figure images.




*********************************
# Functions

This directory contains scripts with functions used to process and analyze the data.   

- The script init_function.R contains a set of functions used to streamline initializing the project.

- The script munge_functions.R contains functions to process the data




