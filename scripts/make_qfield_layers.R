## script to clip all the relevant layers to a specific fire to make a manageable file size for QField (hopefully)

library(here)
library(sf)
library(tidyverse)
library(terra)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))


visitor = rast(datadir("basemaps/SNF map/snf_11.jpg"))
visitor = rast(datadir("basemaps/PNF map/pnf_01_shifted.jpg"))
visitor = rast(datadir("basemaps/MNF_VisitorMap2012_ShadedRelief.pdf"))
visitor = rast(datadir("basemaps/SQF map/sqf_south_10_alb.jpg"))

firename = "castle"

fires = st_read(datadir("fire_perims/DRAFT_Wildfire_Perimeters_2020_DRAFT.gpkg"))

fire_foc = fires %>%
  filter(FIRE_NAME == "CASTLE", REPORT_AC > 10000)

visitor_clip = crop(visitor,fire_foc %>% st_transform(crs(visitor)))

slope = rast(datadir("dem/CAmerged14_albers_slope.tif"))
slope_clip = crop(slope,fire_foc %>% st_transform(crs(slope)))

sev = rast(datadir("fire_severity/ravg_2020_ba7_20210112.tif"))
sev_clip = crop(sev,fire_foc %>% st_transform(crs(sev)))

grid = st_read(datadir("focal_area/candidate_grid_dense_facserot.gpkg"))
grid_intersects = st_intersects(grid,fire_foc %>% st_transform(st_crs(grid)),sparse = FALSE)
grid_clip = grid[grid_intersects,]

grid_transition = st_read(datadir("focal_area/candidate_grid_dense_transition.gpkg"))
grid_transition_intersects = st_intersects(grid_transition,fire_foc %>% st_transform(st_crs(grid_transition)),sparse = FALSE)
grid_transition_clip = grid_transition[grid_transition_intersects,]

spots = st_read(datadir("focal_area/manual_scouted_spots_v2.gpkg"))
spots_intersects = st_intersects(spots,fire_foc %>% st_transform(st_crs(spots)),sparse = FALSE)
spots_clip = spots[spots_intersects,]

spots_transition = st_read(datadir("focal_area/manual_scouted_transition_spots_v2.gpkg"))
spots_transition_intersects = st_intersects(spots_transition,fire_foc %>% st_transform(st_crs(spots_transition)),sparse = FALSE)
spots_transition_clip = spots_transition[spots_transition_intersects,]

writeRaster(slope_clip,datadir(paste0("qfield_prep/",firename,"_slope_clip.tif")),gdal=c("COMPRESS=DEFLATE", "TFW=NO"), NAflag=NA, overwrite=TRUE)
writeRaster(sev_clip,datadir(paste0("qfield_prep/",firename,"_sev_clip.tif")),gdal=c("COMPRESS=DEFLATE", "TFW=NO"), NAflag=NA, overwrite=TRUE)
writeRaster(visitor_clip,datadir(paste0("qfield_prep/",firename,"_visitor_clip.tif")),gdal=c("COMPRESS=DEFLATE", "TFW=NO"), overwrite=TRUE)
st_write(grid_clip,datadir(paste0("qfield_prep/",firename,"_grid_clip.gpkg")),append=FALSE)
st_write(spots_clip,datadir(paste0("qfield_prep/",firename,"_spots_clip.gpkg")),append=FALSE)
st_write(spots_clip,datadir(paste0("qfield_prep/",firename,"_spots_clip.kml")),append=FALSE)
st_write(grid_transition_clip,datadir(paste0("qfield_prep/",firename,"_grid_transition_clip.gpkg")),append=FALSE)
st_write(spots_transition_clip,datadir(paste0("qfield_prep/",firename,"_spots_transition_clip.gpkg")),append=FALSE)
st_write(spots_transition_clip,datadir(paste0("qfield_prep/",firename,"_spots_transition_clip.kml")),append=FALSE)
