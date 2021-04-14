# Find patches that are not too steep and are extensive enough to be worthwhile

library(here)
library(sf)
library(tidyverse)
library(raster)
library(terra)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))


slope = raster(datadir("dem/CAmerged14_albers_slope.tif"))

flat = slope < 40

writeRaster(flat, datadir("dem/flat_areas.tif"))

flat = rast(datadir("dem/flat_areas.tif"))

flat_coarse = aggregate(flat,fact=10)
writeRaster(flat_coarse,datadir("dem/flat_areas_coarse.tif"))
flat_poly = terra::as.polygons(flat_coarse, trunc=FALSE)

writeVector(flat_poly,datadir("dem/flat_poly_coarse"), filetype="ESRI shapefile", overwrite=TRUE)

