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


spots = st_read(datadir("focal_area/candidate_grid_dense_facserot.gpkg"))

### assign unique IDs

## get max existing ID
max = max(spots$ID %>% str_sub(2,-1))
if(max == -Inf | is.na(max)) { 
  max = 0
  spots$ID = NA
}

# how many are NA or null?
is_na = (is.na(spots$ID) | is.null(spots$ID))
n_na = sum(is_na)

#string to put in
a = paste0("F",(1:n_na + max) %>% str_pad(width=6,pad=0))
str_sub(a,5,4) <- "-"

if(n_na > 0) spots[is_na,]$ID = a

spots$name = spots$ID

spots = spots %>%
  rename(FIRE = FIRE_NAME) %>%
  select(name,ID,everything())

st_write(spots, datadir("focal_area/candidate_grid_dense_facserot.gpkg"),append=FALSE)




#### repeat for transition




spots = st_read(datadir("focal_area/candidate_grid_dense_transition.gpkg"))

### assign unique IDs

## get max existing ID
max = max(spots$ID %>% str_sub(2,-1))
if(max == -Inf | is.na(max)) { 
  max = 0
  spots$ID = NA
}

# how many are NA or null?
is_na = (is.na(spots$ID) | is.null(spots$ID))
n_na = sum(is_na)

#string to put in
a = paste0("T",(1:n_na + max) %>% str_pad(width=6,pad=0))
str_sub(a,5,4) <- "-"

if(n_na > 0) spots[is_na,]$ID = a

spots$name = spots$ID

spots = spots %>%
  rename(FIRE = FIRE_NAME) %>%
  select(name,ID,everything())

st_write(spots, datadir("focal_area/candidate_grid_dense_transition.gpkg"),append=FALSE)

