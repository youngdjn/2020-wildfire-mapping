library(here)
library(sf)
library(tidyverse)
library(terra)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))

f1 = rast(datadir("fire_progressions/2020_AUGUST COMPLEX FIRES_00008864/2020_AUGUST COMPLEX FIRES_00008864dob.tif"))
f2 = rast(datadir("fire_progressions/2020_NORTH COMPLEX_00001302/2020_NORTH COMPLEX_00001302dob.tif"))
f3 = rast(datadir("fire_progressions/2020_CREEK_00001391/2020_CREEK_00001391dob.tif"))
f4 = rast(datadir("fire_progressions/2020_CASTLE_00002541/2020_CASTLE_00002541dob.tif"))
f5 = rast(datadir("fire_progressions/2020_CALDWELL_000479/2020_CALDWELL_000479dob.tif"))


a = mosaic(f1,f2)
b = mosaic(a,f3)
c = mosaic(b,f4)
d = mosaic(c,f5)

writeRaster(d,datadir("fire_progressions/2020_combined.tif"))
