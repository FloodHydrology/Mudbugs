#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Title: openSTARS Demo
#Coder: Nate Jones (cnjones7@ua.edu)
#Date: 5/12/2020
#Purpose: Explore openSTARS package for preparing ssn objects
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Source: https://github.com/MiKatt/openSTARS

#Software prep (fow windows machine):
#   Download and install GRASS 7.6 (stand alone option) https://grass.osgeo.org/
#   Open GRASS GIS and install addons using 'g.extension extension=[addon]' in the cmd window. 
#   Required addons include: r.stream.basins, r.stream.distance, r.stream.order and r.hydrodem

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 1: openSTARS demo---------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#1.1 Setup workspace------------------------------------------------------------
#Download packages of interest
library('ssn')
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

#For macs/linux
# initGRASS(gisBase = "/usr/lib/grass74/",
#           home = tempdir(),
#           override = TRUE)

#1.2 Load data into grass-------------------------------------------------------
#Define data paths
dem_path <- system.file("extdata", "nc", "elev_ned_30m.tif", package = "openSTARS")
sites_path <- system.file("extdata", "nc", "sites_nc.shp", package = "openSTARS")
preds_path <- c(system.file("extdata", "nc", "landuse.shp", package = "openSTARS"),
                system.file("extdata", "nc", "pointsources.shp", package = "openSTARS"))

#Setup grass env
setup_grass_environment(dem = dem_path)

#import data
import_data(dem = dem_path, 
            sites = sites_path, 
            predictor_vector = preds_path, 
            predictor_v_names = c("landuse", "psources"))

#Plot data
dem <- readRAST("dem", ignore.stderr = TRUE)
sites <- readVECT("sites_o", ignore.stderr = TRUE)
psources <- readVECT("psources", ignore.stderr = TRUE)
lu <- readVECT("landuse", ignore.stderr = TRUE)

#1.3 Create stream net----------------------------------------------------------
derive_streams()
streams <- readVECT("streams_v", ignore.stderr = TRUE)

#Plot data
plot(dem, col = terrain.colors(20))
lines(streams, col = "blue")
cols <- colorRampPalette(c("blue", "red"))(length(sites$value))[rank(sites$value)]
points(sites, pch = 16, col = cols)

#1.4 Clean edge and point data--------------------------------------------------
#Create edge list
calc_edges()

#Prep sites
calc_sites()
sites <- readVECT("sites", ignore.stderr = TRUE)

#Plot data
dem <- readRAST("dem", ignore.stderr = TRUE)
sites <- readVECT("sites", ignore.stderr = TRUE)
sites_orig <- readVECT("sites_o", ignore.stderr = TRUE)
edges <- readVECT("edges", ignore.stderr = TRUE)
plot(dem, col = terrain.colors(20))
lines(edges, col = "blue")
points(sites_orig, pch = 20, col = "black")
points(sites, pch = 21, cex=0.75, bg = "grey")
legend(x = par("usr")[1]*1.002, y = par("usr")[3]*1.01, col = 1, pt.bg = "grey", pch = c(21, 19), legend = c("snapped sites", "original sites"))

#1.5 Calculate watershed metrics------------------------------------------------
# calculate slope from DEM as an example attribute
execGRASS("r.slope.aspect", flags = c("overwrite","quiet"),
          parameters = list(
            elevation = "dem",
            slope = "slope"
          ))

# calculate average slope per sub-catchment of each stream segment using raster and imported vector data
calc_attributes_edges(input_raster = "slope", stat_rast = "mean",
                      attr_name_rast = "avSlo", input_vector = "landuse", 
                      stat_vect = "percent", attr_name_vect = "landuse", 
                      round_dig = 4)

#calculate approx. catchment area and average slope per catchment of each site
calc_attributes_sites_approx(sites_map = "sites", 
                             input_attr_name = c("avSlo","agri","forest","grass","urban"),
                             output_attr_name = c("avSloA","agriA","forestA","grassA","urbanA"),
                             stat = c("mean", rep("percemt", 4)))
sites <- readVECT("sites", ignore.stderr = TRUE)

#Write ssn object---------------------------------------------------------------
ssn_dir <- file.path(tempdir(), 'nc.ssn')
export_ssn(ssn_dir)
list.files(ssn_dir)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 2. Demo SSN Package-------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#2.1 Load ssn data model--------------------------------------------------------
ssn_obj<-importSSN(ssn_dir, o.write=T)
plot(ssn_obj, 'value')

#2.2 Create distance matrix-----------------------------------------------------
# Create Distance Matrix
createDistMat(ssn_obj, o.write = TRUE)
dmats <- getStreamDistMat(ssn_obj)

ssn_obj.Torg <- Torgegram(ssn_obj, "value", nlag = 20, maxlag = 15000)
plot(ssn_obj.Torg)

#2.3 Linear modeling------------------------------------------------------------
# non-spatial model
ssn_obj.glmssn0 <- glmssn(value ~ upDist, ssn.object = ssn_obj,
                          CorModels = NULL)
summary(ssn_obj.glmssn0)

#spatial model
ssn_obj <- additive.function(ssn_obj, "H2OArea", "computed.afv")
ssn_obj.glmssn1 <- glmssn(value ~ upDist, ssn.object = ssn_obj,
                          CorModels = c("Exponential.taildown", "Exponential.tailup"),
                          addfunccol = "computed.afv")
summary(ssn_obj.glmssn1)
