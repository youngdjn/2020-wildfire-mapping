# assign IDs to new spots that have been added, but start the IDs aboe the ID of the existing ones

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

spots = st_read(datadir("focal_area/manual_scouted_spots_v2.gpkg"))

## get max ID
max(spots$ID %>% str_sub(2,-1))
if(max == -Inf) { 
  max = 0
  spots$ID = NA
}

# how many are NA or null?
is_na = (is.na(spots$ID) | is.null(spots$ID))
n_na = sum(is_na)

if(n_na > 0) spots[is_na,]$ID = paste0("F",(1:n_na + max) %>% str_pad(width=4,pad=0))

spots$name = spots$ID

st_write(spots,datadir("focal_area/manual_scouted_spots_v2.gpkg"),append=FALSE)



#### Repeat for transition spots
spots = st_read(datadir("focal_area/manual_scouted_transition_spots_v2.gpkg"))

## get max ID
max(spots$ID %>% str_sub(2,-1))
if(max == -Inf) { 
  max = 0
  spots$ID = NA
}

# how many are NA or null?
is_na = (is.na(spots$ID) | is.null(spots$ID))
n_na = sum(is_na)

if(n_na > 0) spots[is_na,]$ID = paste0("T",(1:n_na + max) %>% str_pad(width=4,pad=0))

spots$name = spots$ID

st_write(spots,datadir("focal_area/manual_scouted_transition_spots_v2.gpkg"),append=FALSE)
