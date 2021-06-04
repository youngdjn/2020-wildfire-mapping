
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


## get temperature and progression at spots
temperature = rast(datadir("prism/tmean_normal/PRISM_tmean_30yr_normal_800mM2_annual_bil.bil"))
progression = rast(datadir("fire_progressions/2020_combined.tif"))

temperature_dat = extract(temperature,spots %>% st_transform(crs(temperature))%>% vect)
spots$temperature = temperature_dat[,2]

progression_dat = extract(progression,spots %>% st_transform(crs(progression)) %>% vect)
spots$progression = progression_dat[,2]

# stratification implemented here
spots_strat = spots %>%
  dplyr::filter(!is.na(progression)) %>%
  mutate(prog_cat = cut(progression,breaks=c(0,242,256,270,500)) %>% as.numeric,
         temp_cat = cut(temperature,breaks=c(0,8.5,10.5,12.5,500)) %>% as.numeric) %>%
  mutate(prog_temp_cat = paste(prog_cat,temp_cat,sep="_"))


ggplot(spots_strat,aes(x=progression,y=temperature,color=prog_temp_cat)) +
  geom_point() +
  scale_color_viridis_d() +
  scale_x_continuous(n.breaks=10) +
  scale_y_continuous(n.breaks=10)

st_write(spots_strat,datadir("focal_area/manual_scouted_spots_v2.gpkg"),append=FALSE)



#### Repeat for transition spots

spots = st_read(datadir("focal_area/manual_scouted_transition_spots_v2.gpkg"))


## get temperature and progression at spots
temperature = rast(datadir("prism/tmean_normal/PRISM_tmean_30yr_normal_800mM2_annual_bil.bil"))
progression = rast(datadir("fire_progressions/2020_combined.tif"))

temperature_dat = extract(temperature,spots %>% st_transform(crs(temperature))%>% vect)
spots$temperature = temperature_dat[,2]

progression_dat = extract(progression,spots %>% st_transform(crs(progression)) %>% vect)
spots$progression = progression_dat[,2]

# stratification implemented here
spots_strat = spots %>%
  dplyr::filter(!is.na(progression)) %>%
  mutate(prog_cat = cut(progression,breaks=c(0,242,256,270,500)) %>% as.numeric,
         temp_cat = cut(temperature,breaks=c(0,8.5,10.5,12.5,500)) %>% as.numeric) %>%
  mutate(prog_temp_cat = paste(prog_cat,temp_cat,sep="_"))


ggplot(spots_strat,aes(x=progression,y=temperature,color=prog_temp_cat)) +
  geom_point() +
  scale_color_viridis_d() +
  scale_x_continuous(n.breaks=10) +
  scale_y_continuous(n.breaks=10)


st_write(spots_strat,datadir("focal_area/manual_scouted_transition_spots_v2.gpkg"),append=FALSE)

