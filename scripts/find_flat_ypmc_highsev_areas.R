# Find patches that are not too steep and are extensive enough to be worthwhile

library(here)
library(sf)
library(tidyverse)
library(terra)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))

# ypmc = st_read(datadir("eveg/ypmc_poly_coarse/ypmc_poly_coarse.shp"))
# flat = st_read(datadir("dem/flat_poly_coarse/flat_poly_coarse.shp"))



### do it by raster:

ypmc = rast(datadir("eveg/ypmc_rasterized_coarse.tif"))
ypmc[is.na(ypmc)] = 0
flat = rast(datadir("dem/flat_areas_coarse.tif"))

suitable = ypmc > 0.5 & flat > 0.9
plot(suitable)

suitable[suitable == 0] = NA

suitable_poly = terra::as.polygons(suitable,trunc=FALSE)

writeVector(suitable_poly,datadir("focal_area/suitable_veg_slope"),filetype="ESRI shapefile")



## Now also clip to high severity
suitable_poly = st_read(datadir("focal_area/suitable_veg_slope"))
highsev = st_read(datadir("fire_severity/highsev_poly_over50perc/highsev_poly_over50perc.shp"))

# takes like an hour:
suitable_poly_highsev = st_intersection(suitable_poly %>% st_buffer(0),highsev %>% st_transform(st_crs(suitable_poly)) %>% st_buffer(0))
st_write(suitable_poly_highsev,datadir("focal_area/suitable_veg_slope_highsev.gpkg"))
