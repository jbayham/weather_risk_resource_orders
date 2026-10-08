fixest_to_coeftest <- function(fixest.object){
  #Check if arg1 is fixest class
  if(!inherits(fixest.object, "fixest")){
    stop("Not a fixest object")
  }
  
  #Extract the coefficient table
  df <- summary(fixest.object, se = "cluster")$coeftable
  
  #Coerce dataframe into matrix
  coeftest.object <- as.matrix(df)
  
  #Capture variable names from df and rename columns to conform to coeftest
  new_names <- list(rownames(df),
                    c("Estimate","Std. Error","z value","Pr(>|z|)"))
  
  #Assign names
  dimnames(coeftest.object) <- new_names
  
  #re-class to coeftest
  class(coeftest.object) <- 'coeftest'
  
  return(coeftest.object)
  
}
