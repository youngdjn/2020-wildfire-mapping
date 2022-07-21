library(here)
library(sf)
library(tidyverse)
#library(stars)
library(terra)

n# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))

spots = st_read(datadir("focal_area_2022/dixie-scouting-spots.gpkg"))


## make a kml with:
# Name: id_type_clim_dob
# Notes: notes
# type_clim
# type
# clim
# dob

spots = spots %>%
  mutate(id = 1:nrow(spots) %>% str_pad(width=3,side="left",pad="0")) %>%
  mutate(Name = paste0(plot_type,id,"_",clim_type,"_",dob)) %>%
  mutate(type_clim = paste0(plot_type,"_",clim_type)) %>%
  select(Name,notes,plot_type,clim_type,type_clim,dob,id) %>%
  mutate(type_clim = recode(type_clim,"s_" = "s",
                            "s_NA" = "s",
                            "s_ppt-low" = "s"))

st_write(spots,datadir("focal_area_2022/dixie-scouting-spots_enumerated.gpkg"), delete_dsn = TRUE)
st_write(spots,datadir("focal_area_2022/dixie-scouting-spots_enumerated.kml"), delete_dsn = TRUE)

st_write(spots %>% filter(type_clim == "c_ppt-high"),datadir("focal_area_2022/dix_scout_highp.kml"), delete_dsn = TRUE)
st_write(spots %>% filter(type_clim %in% c("c_ppt-low")),datadir("focal_area_2022/dix_scout_lowp.kml"), delete_dsn = TRUE)
st_write(spots %>% filter(type_clim %in% c("c_ppt-low-e","c_sug")),datadir("focal_area_2022/dix_scout_e_lowp.kml"), delete_dsn = TRUE)
st_write(spots %>% filter(type_clim %in% c("s")),datadir("focal_area_2022/dix_scout_s.kml"), delete_dsn = TRUE)
