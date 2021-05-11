## script to clip all the relevant layers to a specific fire to make a manageable file size for QField (hopefully)

library(here)
library(sf)
library(tidyverse)
library(terra)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))

files = list.files(datadir("planned_management"),pattern = ".shp$", recursive=TRUE, full.names=TRUE)
layers = NULL
for(i in 1:length(files)) {
  a = st_read(files[i],drivers="ESRI Shapefile") %>%
    mutate(across(-geometry,as.character))
  layers =bind_rows(layers,a)
}
layers = st_union(layers)
st_write(layers,datadir("planned_management/merged_plumas_management.gpkg"))
