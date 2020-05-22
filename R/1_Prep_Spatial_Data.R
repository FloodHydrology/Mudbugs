#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Title: Spatial Data Prep
#Coder: Nate Jones (cnjones7@ua.edu)
#Date: 5/20/2020
#Purpose: Prep Spatial Data (Cataba River)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#The goal of this script is to prep the spatial data for SSN modeling. Data include:
#   #NHDPlusV2 HydroDem (https://www.epa.gov/waterdata/nhdplus-south-atlantic-west-data-vector-processing-unit-03w)
#   #NHDPlusV2 WBD dataset (same as above)
#   #Reconditioned flowline and prediction points (https://www.fs.fed.us/rm/boise/AWAE/projects/NationalStreamInternet/NSI_network.html)
#   #Mudbug data from Museum (From Emma!)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 1: Setup workspace--------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Clear Memory
remove(list=ls())

#load libraries of interest
library(mapview)
library(raster)
library(sf)
library(lubridate)
library(tidyverse)

#Define data dir
data_dir<-"C:\\Users\\cnjones7\\Box Sync\\My Folders\\Research Projects\\Mudbugs\\data"

#download data
df<-read_csv(paste0(data_dir, "\\I_Data\\Cahaba and Locust data.csv"))
dem<-raster(paste0(data_dir,"\\I_Data\\NHDPlusSA\\NHDPlus03W\\NHDPlusHydrodem03f\\hydrodem"))
sheds<-st_read(paste0(data_dir,"\\I_Data\\NHDPlusSA\\NHDPlus03W\\WBD\\WBD_Subwatershed.shp"))
streams<-st_read(paste0(data_dir,"\\I_Data\\NSI\\Flowline_SA03W_NSI.shp"))
predictions<-st_read(paste0(data_dir,"\\I_Data\\NSI\\PredictionPoints_SA03W_NSI.shp"))
  
#Define master project
p<-dem@crs

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 2: Clip DEM---------------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Clip sheds to cahaba
sheds<-sheds %>% filter(HUC_8 == '03150202') %>% st_transform(., crs=st_crs(dem@crs))

#Clip dem to cahaba
dem<-raster::crop(dem, sheds)
dem<-mask(dem, sheds)

#project dem
dem<-projectRaster(dem, crs=p)
sheds<-sheds %>% st_transform(., st_crs(dem@crs))

#Write sheds and DEM to work folder
st_write(sheds, paste0(data_dir, "\\II_Work\\sheds.shp"), append=T)
writeRaster(dem, paste0(data_dir, "\\II_Work\\dem.tif"), overwrite=T)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 3: Create sampling points-------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Convert df into sf object and project
df<-st_as_sf(df, 
             coords = c("Longitude", "Latitude"), 
             crs = st_crs("+proj=longlat +ellps=GRS80 +datum=NAD83 +no_defs ")) %>% 
  st_transform(., crs=st_crs(p))

#Crop points to watershed
df<-df[sheds,]

#Create shape
df_shp<-df %>% select(crayfishre)

#Clean data
df<-df %>% st_drop_geometry() %>% 
  #create date collumn
  mutate(date = ymd(paste(Year,"-",Month,"-", Day))) %>% 
  #select cols of interest
  select(crayfishre, date, Year, Month, Day, Species) %>% 
  #remove duplicates and na's
  distinct() %>% drop_na() %>% arrange(date) %>% 
  #pivot wider
  mutate(seen=1) %>% 
  pivot_wider(names_from=Species, 
              values_from=seen, 
              values_fill=0)

#Select species of interest and join to back to spatial data
df_shp<-df %>% 
  #Select cols of interest
  select(crayfishre, date, Year, Month, Day, virilis) %>% 
  #join back to shape 
  left_join(df_shp,.) %>% 
  #remove na
  drop_na()

#Export shape
st_write(df_shp, paste0(data_dir, "\\II_Work\\sites.shp"), overwrite=T)
  
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 4: Create prediction points-----------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Reproject streams and then crop to HUC08 of interest
streams <- streams %>% st_transform(., crs=st_crs(p))
streams <- st_zm(streams)
streams <- streams[sheds,]

#Convert streams to prediction points (i.e., shape centroid)
predictions <- predictions %>% st_transform(., crs=st_crs(p))
predictions <- st_zm(predictions)
predictions <- predictions[sheds,]

#Check to make sure they overlap
mapview(list(streams, predictions))

#Export points to working dir
st_write(streams, paste0(data_dir, "\\II_Work\\streams.shp"), append=T)
st_write(predictions, paste0(data_dir, "\\II_Work\\prediction.shp"), append=T)

