# assign IDs to new spots that have been added, but start the IDs aboe the ID of the existing ones

library(here)
library(sf)
library(tidyverse)
#library(raster)
#library(stars)
library(terra)

fire = st_read("/home/derek/Documents/data/2020-wildfire-mapping_data/fire_perims/fire20_1.gdb")


ca = st_read("/home/derek/Documents/data/2020-wildfire-mapping_data/ca_boundary/statep010.shp")

eco = st_read("/home/derek/gis/Ecoregions/us_eco_l4/us_eco_l4_no_st.shp")

eco = st_intersection(eco,ca %>% st_transform(st_crs(eco)))



eco_forest = grepl("Forest|forest",eco$US_L4NAME)
eco = eco[eco_forest,]

eco_sn = grepl("Sierra",eco$US_L4NAME)
eco_sn = eco[eco_sn,]

fire$YEAR_ = as.character(fire$YEAR_)
fire = fire[fire$YEAR_ >= 2017,]

fire = st_make_valid(fire)

library(gdalUtilities)

ensure_multipolygons <- function(X) {
  tmp1 <- tempfile(fileext = ".gpkg")
  tmp2 <- tempfile(fileext = ".gpkg")
  st_write(X, tmp1)
  ogr2ogr(tmp1, tmp2, f = "GPKG", nlt = "MULTIPOLYGON")
  Y <- st_read(tmp2)
  st_sf(st_drop_geometry(X), geom = st_geometry(Y))
}

fire2 = ensure_multipolygons(fire)

fire = fire2 %>% st_union
fire_backup = fire
fire_since2015
fire_since2017


forest_burn = st_intersection(fire,eco %>% st_transform(st_crs(fire)))
sn_burn = st_intersection(fire,eco_sn %>% st_transform(st_crs(fire)))


st_area(forest_burn) %>% sum

(st_area(forest_burn) %>% sum) / (st_area(eco) %>% sum)
(st_area(sn_burn) %>% sum) / (st_area(eco_sn) %>% sum)




# 
# 11% of state forests since 2017
# 13% since 2015


