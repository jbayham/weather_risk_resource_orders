source("functions/commander_names.R")
d <- data.frame(incident_number = letters[1:5], report_date = as.Date("2020-01-01") + 0:4,
  ross_inc_id = 1:5, sitnum = 1L, time_since_disco = 0L,
  ic_name = c("Raw A", "Raw B", "Raw C", "Raw D", NA_character_), measure = 1:5)
l <- data.frame(ross_inc_id = c(1,1,2,2,3,4), sitnum = 1L,
  time_since_disco = c(0,0,0,0,1,0), ic_name = c("clean a","clean a","b one","b two","wrong date",""))
z <- reconcile_commanders(d,l)
stopifnot(identical(z$ic_name,c("clean a","Raw B","Raw C","Raw D",NA_character_)),
          identical(z$measure,d$measure), nrow(z)==nrow(d))
rev <- reconcile_commanders(d,l[nrow(l):1,]);stopifnot(identical(z$ic_name,rev$ic_name))
stopifnot(inherits(try(reconcile_commanders(rbind(d,d[1,]),l),silent=TRUE),"try-error"))
l$ross_inc_id[1] <- NA;stopifnot(inherits(try(reconcile_commanders(d,l),silent=TRUE),"try-error"))
cat("Commander tests passed: cardinality, conflicts, exact duplicates, date keys, missingness, order independence.\n")
