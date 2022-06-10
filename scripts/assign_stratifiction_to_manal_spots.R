
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

# spots = st_read(datadir("focal_area/manual_scouted_spots_v2.gpkg"))
# #new for 2021 fires
# spots = st_read("/Users/derek/Documents/repo_data_local/2022-new-site-gis-scouting-nina/candidate-sites/candidate-sites-general-centroids.gpkg")
# 

# read polys

polys = st_read("/Users/derek/Documents/repo_data_local/2022-new-site-gis-scouting-nina/candidate-sites/candidate-sites-general.gpkg")

polys$type_coarse = recode(polys$type,
                           bk = "hs",
                           br = "hs",
                           m = "hs")

# get centroids

spots = st_centroid(polys)



## get temperature and progression at spots
temperature = rast(datadir("prism/tmean_normal/PRISM_tmean_30yr_normal_800mM2_annual_bil.bil"))
progression = rast(datadir("fire_progressions/2020_combined.tif"))
progression = rast(datadir("fire_progressions_2021/2021CALDOR/2021CALDOR_dob.tif"))

temperature_dat = extract(temperature,spots %>% st_transform(crs(temperature))%>% vect)
spots$temperature = temperature_dat[,2]

progression_dat = extract(progression,spots %>% st_transform(crs(progression)) %>% vect)
spots$progression = progression_dat[,2]

# how to stratify?
ggplot(spots,aes(x=temperature,y=progression)) +
  geom_point()

# stratification implemented here
spots_strat = spots %>%
  dplyr::filter(!is.na(progression)) %>%
  mutate(prog_cat = cut(progression,breaks=c(0,242,256,270,500)) %>% as.numeric,
         temp_cat = cut(temperature,breaks=c(0,8.5,10.5,12.5,500)) %>% as.numeric) %>%
  mutate(prog_temp_cat = paste(prog_cat,temp_cat,sep="_"))


# stratification implemented here
spots_strat = spots %>%
  dplyr::filter(!is.na(progression)) %>%
  mutate(prog_cat = cut(progression,breaks=c(0,235.5,500)) %>% as.numeric,
         temp_cat = cut(temperature,breaks=c(0,8,10,12,500)) %>% as.numeric) %>%
  mutate(prog_temp_cat = paste(prog_cat,temp_cat,sep="_"))



ggplot(spots_strat,aes(x=progression,y=temperature,color=prog_temp_cat)) +
  geom_point() +
  scale_color_viridis_d() +
  scale_x_continuous(n.breaks=10) +
  scale_y_continuous(n.breaks=10)

st_write(spots_strat,datadir("focal_area/manual_scouted_spots_v2.gpkg"),append=FALSE)



# #### Repeat for transition spots
# 
# spots = st_read(datadir("focal_area/manual_scouted_transition_spots_v2.gpkg"))
# 
# 
# ## get temperature and progression at spots
# temperature = rast(datadir("prism/tmean_normal/PRISM_tmean_30yr_normal_800mM2_annual_bil.bil"))
# progression = rast(datadir("fire_progressions/2020_combined.tif"))
# 
# temperature_dat = extract(temperature,spots %>% st_transform(crs(temperature))%>% vect)
# spots$temperature = temperature_dat[,2]
# 
# progression_dat = extract(progression,spots %>% st_transform(crs(progression)) %>% vect)
# spots$progression = progression_dat[,2]
# 
# # stratification implemented here
# spots_strat = spots %>%
#   dplyr::filter(!is.na(progression)) %>%
#   mutate(prog_cat = cut(progression,breaks=c(0,242,256,270,500)) %>% as.numeric,
#          temp_cat = cut(temperature,breaks=c(0,8.5,10.5,12.5,500)) %>% as.numeric) %>%
#   mutate(prog_temp_cat = paste(prog_cat,temp_cat,sep="_"))
# 
# 
# ggplot(spots_strat,aes(x=progression,y=temperature,color=prog_temp_cat)) +
#   geom_point() +
#   scale_color_viridis_d() +
#   scale_x_continuous(n.breaks=10) +
#   scale_y_continuous(n.breaks=10)


# give them IDs

spots_strat = spots_strat %>%
  mutate(type_cs = recode(type_coarse,
                   sw = "S",
                   g = "C",
                   hs = "C")) %>%
  mutate(idnum = 1:nrow(spots_strat) %>% str_pad(3,side="left",pad="0")) %>%
  mutate(spot_id = paste0(type_cs,idnum)) %>%
  mutate(Name = paste0(spot_id," ",type," ",prog_temp_cat))


st_write(spots_strat,("/Users/derek/Documents/repo_data_local/2022-new-site-gis-scouting-nina/candidate-sites/candidate-sites-general-centroids-strat.gpkg"), delete_dsn= TRUE)
st_write(spots_strat,("/Users/derek/Documents/repo_data_local/2022-new-site-gis-scouting-nina/candidate-sites/candidate-sites-general-centroids-strat.kml"), delete_dsn= TRUE)

## also write perimeters for each category (green, highsev, and sw) for avenza points
spots_nonsp = spots_strat
st_geometry(spots_nonsp) = NULL
polys_w_data = bind_cols(polys %>% select(-type,-type_coarse),spots_nonsp)


st_write(polys_w_data %>% filter(type_coarse == "hs"),"/Users/derek/Documents/repo_data_local/2022-new-site-gis-scouting-nina/candidate-sites/candidate-sites-general-polys-hs.kml", delete_dsn= TRUE)
st_write(polys_w_data %>% filter(type_coarse == "g"),"/Users/derek/Documents/repo_data_local/2022-new-site-gis-scouting-nina/candidate-sites/candidate-sites-general-polys-g.kml", delete_dsn= TRUE)
st_write(polys_w_data %>% filter(type_coarse == "sw"),"/Users/derek/Documents/repo_data_local/2022-new-site-gis-scouting-nina/candidate-sites/candidate-sites-general-polys-sw.kml", delete_dsn= TRUE)
st_write(polys_w_data,"/Users/derek/Documents/repo_data_local/2022-new-site-gis-scouting-nina/candidate-sites/candidate-sites-general-polys-all.kml", delete_dsn= TRUE)


# make an avenza basemap with the stratification symbology

# make an avenza basemap with planet imagery





