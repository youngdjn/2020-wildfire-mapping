# Find patches that are not too steep and are extensive enough to be worthwhile

library(here)
library(sf)
library(tidyverse)
library(raster)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))


slope = raster(datadir("dem/CAmerged14_albers_slope.tif"))

flat = slope < 40

writeRaster(flat, datadir("dem/flat_areas.tif"))

flat_clump = clump(flat, directions=4)

#get clump size as df
clump_df <- na.omit(subset(as.data.frame(freq(flat_clump)), count > 0))

# create a raster with flat area size
flat_clump_size = reclassify(flat_clump,clump_df)


