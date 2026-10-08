# Explicit setup step; installs only into repository-local audit-library.
# Network access and an R-compatible C++ compiler are required for fixest 0.2.1.
lib<-file.path(getwd(),"audit-library");dir.create(lib,showWarnings=FALSE)
.libPaths(c(lib,.libPaths()))
pkgs<-c("dplyr","tidyr","purrr","stringr","readr","tibble","lubridate","haven","ggplot2","skimr",
 "lmtest","sandwich","broom","DescTools","margins","MASS","numDeriv","rmarkdown","knitr","Rcpp","dreamerr")
missing<-pkgs[!vapply(pkgs,requireNamespace,logical(1),quietly=TRUE)]
if(requireNamespace("dplyr",quietly=TRUE) && packageVersion("dplyr")<"1.1.0") missing<-union(missing,"dplyr")
if(length(missing))install.packages(missing,lib=lib,repos="https://cloud.r-project.org")
if(!requireNamespace("fixest",quietly=TRUE)||packageVersion("fixest")!="0.2.1") {
 build<-file.path(getwd(),"audit-output/dependencies");dir.create(build,recursive=TRUE,showWarnings=FALSE)
 archive<-file.path(build,"fixest_0.2.1.tar.gz")
 download.file("https://cran.r-project.org/src/contrib/Archive/fixest/fixest_0.2.1.tar.gz",archive,mode="wb")
 # Digest checks the original archive, before the documented compiler-only patch.
 if(!requireNamespace("digest",quietly=TRUE))install.packages("digest",lib=lib,repos="https://cloud.r-project.org")
 stopifnot(digest::digest(file=archive,algo="sha256")=="1adaf784ee59891ab6df2f810004c307d002bb406c8799257ab088a7f39743ff")
 untar(archive,exdir=build)
 cpp<-file.path(build,"fixest/src/parallel_funs.cpp")
 writeLines(c("#include <cfloat>","#ifndef DOUBLE_EPS","#define DOUBLE_EPS DBL_EPSILON","#endif",readLines(cpp)),cpp)
 install.packages(file.path(build,"fixest"),repos=NULL,type="source",lib=lib)
}
stopifnot(packageVersion("fixest")=="0.2.1",packageVersion("dplyr")>="1.1.0")
cat("Dependencies ready in audit-library. Pandoc is also needed for HTML rendering.\n")
