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

firename = "north"

fires = st_read(datadir("fire_perims/DRAFT_Wildfire_Perimeters_2020_DRAFT.gpkg"))

fire_foc = fires %>%
  filter(FIRE_NAME == "CASTLE", REPORT_AC > 10000)
fire_foc = fires %>%
  filter(FIRE_NAME == "NORTH COMPLEX", REPORT_AC > 10000)
fire_foc = fires %>%
  filter(FIRE_NAME == "AUGUST COMPLEX FIRES")
fire_foc = fires %>%
  filter(FIRE_NAME == "CREEK", REPORT_AC > 10000)

visitor_clip = crop(visitor,fire_foc %>% st_transform(crs(visitor)))

slope = rast(datadir("dem/CAmerged14_albers_slope.tif"))
slope_clip = crop(slope,fire_foc %>% st_transform(crs(slope)))

sev = rast(datadir("fire_severity/ravg_2020_ba7_20210112.tif"))
sev_clip = crop(sev,fire_foc %>% st_transform(crs(sev)))

grid = st_read(datadir("focal_area/new_grid_north.gpkg"))
spots = st_read(datadir("focal_area/new_spots_cent_north.gpkg"))
spots_poly = st_read(datadir("focal_area/new_spots_poly_north.gpkg"))


writeRaster(slope_clip,datadir(paste0("qfield_prep2/",firename,"_slope_clip.tif")),gdal=c("COMPRESS=DEFLATE", "TFW=NO"), NAflag=NA, overwrite=TRUE)
writeRaster(sev_clip,datadir(paste0("qfield_prep2/",firename,"_sev_clip.tif")),gdal=c("COMPRESS=DEFLATE", "TFW=NO"), NAflag=NA, overwrite=TRUE)
writeRaster(visitor_clip,datadir(paste0("qfield_prep2/",firename,"_visitor_clip.tif")),gdal=c("COMPRESS=DEFLATE", "TFW=NO"), overwrite=TRUE)
st_write(grid,datadir(paste0("qfield_prep2/",firename,"_grid.gpkg")),append=FALSE)
st_write(spots,datadir(paste0("qfield_prep2/",firename,"_spots_centers.gpkg")),append=FALSE)
st_write(spots,datadir(paste0("qfield_prep2/",firename,"_spots_centers_all.kml")),append=FALSE)
st_write(spots_poly,datadir(paste0("qfield_prep2/",firename,"_spots_polys.gpkg")),append=FALSE)
st_write(spots_poly,datadir(paste0("qfield_prep2/",firename,"_spots_polys_all.kml")),append=FALSE)

# make a set of polygons and centers that excludes DM
spots_nodm = spots %>%
  filter(prefix != "D")
spots_poly_nodm = spots_poly %>%
  filter(prefix != "D")

st_write(spots_nodm,datadir(paste0("qfield_prep2/",firename,"_spots_centers_nodm.kml")),append=FALSE)
st_write(spots_poly_nodm,datadir(paste0("qfield_prep2/",firename,"_spots_polys_nodm.kml")),append=FALSE)





