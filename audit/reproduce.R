# Run from repository root: Rscript --vanilla audit/reproduce.R
# Optional dependency library roots, separated by the platform path separator.
libs <- Sys.getenv("WEATHER_R_LIBS")
if (nzchar(libs)) .libPaths(c(strsplit(libs, .Platform$path.sep, fixed = TRUE)[[1]], .libPaths()))
if (dir.exists("audit-library")) .libPaths(c(normalizePath("audit-library"),.libPaths()))
required <- c("dplyr","tidyr","purrr","stringr","readr","tibble","lubridate","haven",
 "ggplot2","skimr","fixest","lmtest","sandwich","broom","DescTools","margins","MASS","numDeriv","rmarkdown","knitr")
missing <- required[!vapply(required,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) stop("Install required packages first; see audit/README.md: ",paste(missing,collapse=", "))
if(packageVersion("fixest") != "0.2.1") stop("This audit pins fixest 0.2.1; see audit/install.R")
for(p in setdiff(required,c("MASS","numDeriv","rmarkdown","knitr"))) suppressPackageStartupMessages(library(p,character.only=TRUE))
root <- normalizePath(".")
if(!file.exists("build/code/08_create_analysis_ds.R")) stop("Run from repository root")
source("audit/tests/test_commander.R")
inputs <- c("incident.Rdata","resources.Rdata","environment.Rdata","weather.Rdata","ross.Rdata","preparedness.Rdata","ic_names-csv.csv")
stopifnot(all(file.exists(file.path("build/cache",inputs))))
source_files <- c(file.path("build/cache",inputs),"build/cache/temp_ds.Rdata")
before <- tools::md5sum(source_files)
# All cache rebuilding occurs in isolated generated working directories.
for(mode in c("corrected","historical","legacy")) {
  work <- file.path(root,"audit-output",mode);dir.create(work,recursive=TRUE,showWarnings=FALSE)
  for(dir in c("analysis/code","build/code","functions","build/cache","analysis/inputs","analysis/cache","report/figures","report/tables/need_formatting","audit/tests"))
    dir.create(file.path(work,dir),recursive=TRUE,showWarnings=FALSE)
  for(dir in c("analysis/code","build/code","functions","audit/tests")) {
    files <- list.files(file.path(root,dir),full.names=TRUE)
    stopifnot(all(file.copy(files,file.path(work,dir),overwrite=TRUE)))
  }
  stopifnot(all(file.copy(file.path(root,"build/cache",inputs),file.path(work,"build/cache"),overwrite=TRUE)))
  stopifnot(all(file.copy(file.path(root,c("report/var_names.csv","report/wx_names.csv")),file.path(work,"report"),overwrite=TRUE)))
  setwd(work);options(weather.audit.commander=mode)
  source("functions/init_functions.R");source("functions/munge_functions.R");source("functions/analysis_functions.R")
  my_skim <- skim_with(numeric=sfl(mean=~mean(.,na.rm=TRUE),sd=~sd(.,na.rm=TRUE),min=~min(.,na.rm=TRUE),max=~max(.,na.rm=TRUE)),append=FALSE)
  source("build/code/00_build.R")
  source("analysis/code/03_resource_orders.R")
  if(mode=="corrected") {
    source("analysis/code/01-growth.R")
    source("analysis/code/02_growth_potential.R")
    out <- "analysis/cache/gp";source("audit/tests/test_ordered_logit.R")
    source("analysis/code/06_tab_gp_evac_forRR.R")
  }
  setwd(root)
}
stopifnot(identical(before,tools::md5sum(source_files)))
options(weather.audit.commander="corrected")
source("audit/export.R")
source("audit/tests/test_results.R")
status <- system2("python3", "audit/compare_stata.py")
if(status != 0L) stop("Saved Stata comparison failed")
# Render only regenerated, supported sections; missing map and raw extraction explicit.
rmarkdown::render("report/Supplement.Rmd",output_file="Supplement-audit.html",quiet=TRUE,
                  envir=new.env(parent=globalenv()),knit_root_dir=root)
html <- readLines("report/Supplement-audit.html", warn=FALSE)
stopifnot(sum(grepl("data:image/png;base64,",html,fixed=TRUE)) >= 15L,
          !any(grepl('src="report/audit/figures/',html,fixed=TRUE)))
cat("Audit completed. See report/audit, report/Supplement-audit.html and audit-output.\n")
