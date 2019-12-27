#Overview

This document is the project readme and contains information about the files in the project folders.  The project data is stored in the data folder.  The cache folder stores copies of data during intermediate steps in the preprocessing steps.  The munge folder contains all scripts to read in and preprocess the data.  The analysis folder contains scripts to run the analysis.  The figures folder is a repository for images produced by the analysis scripts.  

The preamble script located in the root folder should load (and install if not loaded) the packages needed to construct the dataset and run the analysis.  The preamble will also prompt you to compile the dataset by calling a script in the munge folder that runs a series of scripts to import and process Chris Dunn's data stored in MS Access DBs.

Note that all file references within project are relative to the root directory of the project.



**********************

#Project-Objective

The objective of the project is to explore the relationship between fire suppression resource use and weather.  Do incident commanders respond to past, current, and/or forecasted weather?  Do they take advantage of periods of low growth as mentioned in Finney (2009)?  Or, are resources reallocated to other fires with pressing needs?

We will estimate an econometric model of suppression resource mob/demob as a function of weather conditions, values at risk, and resource constraints.



#Data

The data folder contains two MS Access DBs compiled by Chris Dunn.  The two datasets appear to contain much of the same information but one contains Matt Jolly's weather data and the other contains U of I weather data.  The excel file titled MetaData provides descriptions of the tables in the Access DBs.

Data sources:  

* U of I weather data is from the gridMet product (ABATZOGLOU Lab).  This is the source for the BI, ERC, precipitation, minimum humidity, maximum temperature, and wind.  Note that the BI and ERC are calculated (or calibrated) for fuel model G (http://www.climatologylab.org/gridmet.html).

#Munge (data preprocessing)

The munge folder contains a series of numbered scripts.  These scripts should be run in order to reproduce the dataset.

* The script 00-compile_data.R loads the data.  If the intermediate datasets have been cached, they are loaded and compiled.  If they have not been cached or the user wishes to regenerate them, scripts to import and clean the data are called.

* The script 01-read_in_incident.R imports the 209 incident table from Dunn's DB.  This appears to be a subset of fires not in complexes and with more than three reports.

* The script 02-read_in_resources.R imports the resource tables from Dunn's DB.  The resource reporting appears to have changed in 2001 or 2002 so I append the tables together.  Pre-2002, strike teams and single resources are aggregated.  

* The script 03-read_in_environment.R imports the data from the topography tables and vegetation tables in Dunn's DB.  These are all of the time-invariant environmental controls used in subsequent models.

* The script 04-read_in_wui.R imports the data from the wui table in Dunn's DB.  The wui data is from Radeloff's Silvis Lab.

* The script 05-read_in_weather.R imports weather data from tables both Access DBs.  One of the DBs contains tables with BI (burning index), ERC (energy release component), and SFWP (severe fire weather potential).  The DB call UofI contains data on max temperature, minimum humidity, precipitation, and wind.


# Functions
This folder contains scripts with functions used to analyze the data.   

* The script analysis_functions.R contains two functions.  The first is dlm.loop, which loops over arguments to produce the dotwhisker plots to visualize distributed lag model coefficients.  The second is dlm.loop.iso, which is similar to dlm.loop but runs a separate regression for each lag variable.

# Analysis

The analysis folder contains script to conduct analyses and produce figures (scripts with fig_ prefix).

* 01_random_Forest_variable_selection.R runs a random forest model of final fire size on only time-invariant variables (mostly topographic and vegetation).  The package randomforestexplainer generates an html page with useful metrics on the most important variables among the many options Chris created.  The variables with high importance scores are used as controls in the distributed lag model.

* 02_distributed_lag_model.R script runs the distributed lag model in levels and first differences and produces plots of coefficients.  

* fig_correlations.R generates correlation plots for the weather variables using the package corrplot






<!--stackedit_data:
eyJoaXN0b3J5IjpbMTQ2Nzk0NTE4M119
-->