library(here)
library(sf)
library(tidyverse)
#library(raster)
#library(stars)
library(terra)


# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))


facserot = st_read(datadir("focal_area/manual_scouted_spots_v2.gpkg")) %>% mutate(type="serotiny") %>% select(type)
transition = st_read(datadir("focal_area/manual_scouted_transition_spots_v2.gpkg")) %>% mutate(type="transition") %>% select(type)

merged = rbind(facserot,transition)

st_write(merged,datadir("focal_area/manual_scouted_spots_merged_for_perimt"),driver="ESRI Shapefile")
