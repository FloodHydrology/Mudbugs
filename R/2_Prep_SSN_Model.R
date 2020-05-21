#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Title: SSN Model Prep
#Coder: Nate Jones (cnjones7@ua.edu)
#Date: 5/21/2020
#Purpose: Prep SSN Data (Cataba River)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Source: https://github.com/MiKatt/openSTARS

#Software prep (fow windows machine):
#   Download and install GRASS 7.6 (stand alone option) https://grass.osgeo.org/
#   Open GRASS GIS and install addons using 'g.extension extension=[addon]' in the cmd window. 
#   Required addons include: r.stream.basins, r.stream.distance, r.stream.order and r.hydrodem


#Note on software gymnastics:
#   See comment here: https://gis.stackexchange.com/questions/254813/rgrass7-init-error
#   BAsically, GRASS + R is a huge PITa. YOu need to restart your PC 
#   everytime you run RGRASS. Also, you may need to run the following command 
#   in the terminal to complete GIT commits:  
#   $ git config --global user.name "validName"  

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 1: Setup workspace--------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Clear Memory
remove(list=ls())

#Start time
t0<-Sys.time()

#Download packages of interest
library('SSN')
library("openSTARS")
library('rgrass7')
library('raster')

#Tell rgrass7 to use sp object (I know, this hurts my sole. SF is much preferred)
use_sp()

#Initiate grass session
initGRASS("C:/Program Files/GRASS GIS 7.6",
          override = TRUE,
          gisDbase = "GRASS_TEMP",
          home = tempdir(),
          remove_GISRC = TRUE)

#For macs/linux: initGRASS(gisBase = "/usr/lib/grass74/",home = tempdir(),override = TRUE)

#Define data dir
data_dir<-"C:\\Users\\cnjones7\\Box Sync\\My Folders\\Research Projects\\Mudbugs\\data"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 2: Load existing data into grass environment------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Define data paths
dem_path       <- paste0(data_dir, "\\II_Work\\dem.tif")
sites_path     <- paste0(data_dir, "\\II_Work\\sites.shp")
streams_path   <- paste0(data_dir, "\\II_Work\\streams.shp")
pred_site_path <- paste0(data_dir, "\\II_Work\\prediction.shp")
# preds_path <- c(system.file("extdata", "nc", "landuse.shp", package = "openSTARS"),
#                 system.file("extdata", "nc", "pointsources.shp", package = "openSTARS"))

#Setup grass env
setup_grass_environment(dem = paste0(data_dir, "\\II_Work\\dem.tif"))

#import data
import_data(dem = dem_path, 
            sites = sites_path,
            streams = streams_path,
            pred_sites = pred_site_path)
            # predictor_vector = preds_path, 
            # predictor_v_names = c("landuse", "psources"))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 3: Create Derived Dataset-------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# #Derive stream network
derive_streams(burn = 5, 
               condition=F)

#Create edge list
calc_edges()

#preop sites
calc_sites()

#Stop time
tf<-Sys.time()
tf-t0

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 4: Write ssn object-------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ssn_dir <- file.path(paste0(data_dir, "//II_Work"), 'cataba.ssn')
export_ssn(ssn_dir)
list.files(ssn_dir)







