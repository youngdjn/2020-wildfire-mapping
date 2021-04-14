library(here)
library(sf)
library(dplyr)
library(raster)
library(fasterize)
#library(stars)
library(terra)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))

raster_template = raster(datadir("dem/CAmerged14_albers_slope.tif"))
a = raster_template * NA

eveg_ncoast = st_read(datadir("eveg/S_USA.EVMid_R05_NorCoastEast.gdb"))
eveg_scoast = st_read(datadir("eveg/S_USA.EVMid_R05_NorCoastMid.gdb"))
eveg_sscoast = st_read(datadir("eveg/S_USA.EVMid_R05_NorCoastWest.gdb"))
eveg_nsierra = st_read(datadir("eveg/S_USA.EVMid_R05_NorthSierra.gdb"))
eveg_ssierra = st_read(datadir("eveg/S_USA.EVMid_R05_SouthSierra.gdb"))

# retain only ypmc veg of each
whr_focal = c("DFR","EPN","JPN","MHC","PPN","SMC","WFR")                
eveg_ncoast  = eveg_ncoast %>%
  filter(CWHR_TYPE %in% whr_focal | (COVERTYPE == "CON" & (!(CWHR_TYPE %in% c("RFR","LPN","SCN")))))
eveg_scoast  = eveg_scoast %>%
  filter(CWHR_TYPE %in% whr_focal | (COVERTYPE == "CON" & (!(CWHR_TYPE %in% c("RFR","LPN","SCN")))))
eveg_sscoast  = eveg_sscoast %>%
  filter(CWHR_TYPE %in% whr_focal | (COVERTYPE == "CON" & (!(CWHR_TYPE %in% c("RFR","LPN","SCN")))))
eveg_nsierra  = eveg_nsierra %>%
  filter(CWHR_TYPE %in% whr_focal | (COVERTYPE == "CON" & (!(CWHR_TYPE %in% c("RFR","LPN","SCN")))))
eveg_ssierra  = eveg_ssierra %>%
  filter(CWHR_TYPE %in% whr_focal | (COVERTYPE == "CON" & (!(CWHR_TYPE %in% c("RFR","LPN","SCN")))))

eveg = bind_rows(eveg_ncoast,eveg_scoast,eveg_sscoast,eveg_nsierra,eveg_ssierra)

eveg$type_cat = 1
eveg_proj = st_transform(eveg,st_crs(raster_template))
eveg_rast = fasterize(eveg_proj,raster_template,field="type_cat",fun="max")

writeRaster(eveg_rast,datadir("eveg/ypmc_rasterized.tif"))


### Read in to STARS to vectorize, buffer, save

# eveg = read_stars(datadir("eveg/ypmc_rasterized.tif"), proxy=FALSE)
# eveg_poly = st_as_sf(eveg)

eveg_raster = rast(datadir("eveg/ypmc_rasterized.tif"))

eveg_raster[is.na(eveg_raster)] = 0

eveg_coarse = aggregate(eveg_raster, fact=10, fun="mean")
eveg_coarse[eveg_coarse == 0] = NA

eveg_poly = terra::as.polygons(eveg_coarse,trunc=FALSE)

writeVector(eveg_poly,datadir("eveg/ypmc_poly_coarse"), filetype="ESRI shapefile", overwrite=TRUE)

