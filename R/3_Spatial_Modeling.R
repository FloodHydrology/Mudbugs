#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Title: Spatial Modeling
#Coder: Nate Jones (cnjones7@ua.edu)
#Date: 5/21/2020
#Purpose: Model Mudbug Invasion over time!
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 1: Setup workspace--------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Clear Memory
remove(list=ls())

#Download packages of interest
library(tidyverse)
library(SSN)

#Define data directory
data_dir<-"C:\\Users\\cnjones7\\Box Sync\\My Folders\\Research Projects\\Mudbugs\\data"

#Load SSN Object
#ssn_dir<-file.path(paste0(data_dir, "//II_Work"), 'cataba.ssn')
ssn_obj<-importSSN(ssn_dir, o.write=T)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 2: Initial Model----------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
createDistMat(ssn_obj, o.write = TRUE)
dmats <- getStreamDistMat(ssn_obj)

ssn_obj.Torg <- Torgegram(ssn_obj, "virilis", nlag = 20, maxlag = 15000)
plot(ssn_obj.Torg)

#spatial model
ssn_obj <- additive.function(ssn_obj, "H2OArea", "computed.afv")
ssn_obj.glmssn1 <- glmssn(virilis ~ upDist + Year, ssn.object = ssn_obj,
                          CorModels = c("Exponential.taildown", "Exponential.tailup"),
                          addfunccol = "computed.afv")
summary(ssn_obj.glmssn1)

