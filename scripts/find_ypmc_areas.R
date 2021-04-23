library(here)
library(sf)
library(tidyverse)
library(raster)
library(fasterize)
#library(stars)
library(terra)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))

if(!file.exists(datadir("focal_area/template_raster.tif"))) {
  raster_template = rast(datadir("dem/CAmerged14_albers_slope.tif"))
  values(raster_template) = NA
  a = project(raster_template,y = "+proj=longlat +ellps=GRS80 +datum=NAD83 +no_defs")
  
  writeRaster(a,datadir("focal_area/template_raster.tif"),overwrite=TRUE)
}
raster_template = raster(datadir("focal_area/template_raster.tif"))

eveg_ncoast = st_read(datadir("eveg/S_USA.EVMid_R05_NorCoastEast.gdb"))
eveg_scoast = st_read(datadir("eveg/S_USA.EVMid_R05_NorCoastMid.gdb"))
eveg_sscoast = st_read(datadir("eveg/S_USA.EVMid_R05_NorCoastWest.gdb"))
eveg_nsierra = st_read(datadir("eveg/S_USA.EVMid_R05_NorthSierra.gdb"))
eveg_ssierra = st_read(datadir("eveg/S_USA.EVMid_R05_SouthSierra.gdb"))
eveg_ninterior = st_read(datadir("eveg/S_USA.EVMid_R05_NorthInterior.gdb"))

# retain only ypmc veg of each
#whr_focal = c("DFR")                
whr_focal = c("DFR","EPN","JPN","MHC","PPN","SMC","WFR","KMC")
whr_focal = c("DFR")
whr_focal = c("MCH","MCP")

eveg_ncoast2  = eveg_ncoast %>%
  filter(CWHR_TYPE %in% whr_focal)
eveg_scoast2  = eveg_scoast %>%
  filter(CWHR_TYPE %in% whr_focal)
eveg_sscoast2  = eveg_sscoast %>%
  filter(CWHR_TYPE %in% whr_focal)
eveg_nsierra2  = eveg_nsierra %>%
  filter(CWHR_TYPE %in% whr_focal)
eveg_ssierra2  = eveg_ssierra %>%
  filter(CWHR_TYPE %in% whr_focal)
eveg_ninterior2  = eveg_ninterior %>%
  filter(CWHR_TYPE %in% whr_focal)

eveg = bind_rows(eveg_ncoast2,eveg_scoast2,eveg_sscoast2,eveg_nsierra2,eveg_ssierra2,eveg_ninterior2)
eveg_full = bind_rows(eveg_ncoast,eveg_scoast,eveg_sscoast,eveg_nsierra,eveg_ssierra,eveg_ninterior)

types = unique(eveg_full$CWHR_TYPE)

type_table = data.frame(CWHR_TYPE = types,cwhr_code=1:length(types))

write_csv(type_table,datadir("eveg/cwhrtype_lookup_table.csv"))

eveg_full = eveg_full %>%
  left_join(type_table)

bbox = st_bbox(eveg)
raster_template = rast(xmin=bbox$xmin,xmax=bbox$xmax,ymin=bbox$ymin,ymax=bbox$ymax,res=.0003,crs="+proj=longlat +ellps=GRS80 +datum=NAD83 +no_defs")
raster_template = raster(raster_template)

eveg$type_cat = 1
#eveg_proj = st_transform(eveg,st_crs(raster_template))
eveg_rast = fasterize(eveg_full,raster_template,field="cwhr_code",fun="max")

writeRaster(eveg_rast,datadir("eveg/cwhrtype_rasterized.tif"), overwrite=TRUE)

### Read in to STARS to vectorize, buffer, save

# eveg = read_stars(datadir("eveg/ypmc_rasterized.tif"), proxy=FALSE)
# eveg_poly = st_as_sf(eveg)

eveg_raster = rast(datadir("eveg/ypmc_rasterized.tif"))

eveg_raster[is.na(eveg_raster)] = 0

eveg_coarse = aggregate(eveg_raster, fact=10, fun="mean")
eveg_coarse[eveg_coarse == 0] = NA
writeRaster(eveg_coarse,datadir("eveg/ypmc_rasterized_coarse.tif"))

eveg_poly = terra::as.polygons(eveg_coarse,trunc=FALSE)

writeVector(eveg_poly,datadir("eveg/ypmc_poly_coarse"), filetype="ESRI shapefile", overwrite=TRUE)

