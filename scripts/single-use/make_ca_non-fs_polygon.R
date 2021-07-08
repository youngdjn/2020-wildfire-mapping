## script to clip all the relevant layers to a specific fire to make a manageable file size for QField (hopefully)

library(here)
library(sf)
library(tidyverse)
library(terra)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))


ca = st_read(datadir("ca_boundary/statep010.shp")) %>% st_transform(3310)

fs = st_read(datadir("ownership/fsland_ca.gpkg"))

fs = fs %>% st_transform(3310) %>% st_buffer(0) %>% st_union()
plot(fs)

ca_non_fs = st_difference(ca,fs)

st_write(ca_non_fs,datadir("ownership/ca_non-fs_land.gpkg"))
