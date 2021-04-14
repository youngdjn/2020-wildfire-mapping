library(here)
library(sf)
library(dplyr)
# library(raster)
library(fasterize)
#library(stars)
library(terra)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))

sev = rast(datadir("fire_severity/ravg_2020_ba7_20210112.tif"))
template = rast(datadir("dem/CAmerged14_albers_slope.tif"))

ca_mask = st_read(datadir("ca_boundary/statep010.shp"))

# gives a weird error; bug in terra: sev = crop(sev,ca_mask %>% st_transform(sev))

high_sev = sev
high_sev[high_sev != 7] = 0

highsev_coarse = aggregate(high_sev, fact=5, fun="mean")
writeRaster(highsev_coarse,datadir("fire_severity/highsev_coarse.tif"),overwrite=TRUE)

highsev_coarse_over50perc = highsev_coarse
highsev_coarse_100perc = highsev_coarse
highsev_coarse_over50perc[highsev_coarse_over50perc < 3.5] = NA
highsev_coarse_over50perc[highsev_coarse_over50perc >= 3.5] = 1
highsev_coarse_100perc[highsev_coarse_100perc < 7] = NA

highsev_poly_over50perc = terra::as.polygons(highsev_coarse_over50perc,trunc=FALSE)
highsev_poly_100perc = terra::as.polygons(highsev_coarse_100perc,trunc=FALSE)


writeVector(highsev_poly_over50perc,datadir("fire_severity/highsev_poly_over50perc"), filetype="ESRI shapefile", overwrite=TRUE)
writeVector(highsev_poly_100perc,datadir("fire_severity/highsev_poly_100perc"), filetype="ESRI shapefile", overwrite=TRUE)

