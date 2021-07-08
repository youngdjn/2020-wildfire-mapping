## script to clip all the relevant layers to a specific fire to make a manageable file size for QField (hopefully)

library(here)
library(sf)
library(tidyverse)
library(terra)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))


spots = st_read(datadir("focal_area/manual_scouted_spots_v2.gpkg"))

fires = st_read(datadir("fire_perims/DRAFT_Wildfire_Perimeters_2020_DRAFT.gpkg")) %>%
  filter(FIRE_NAME %in% c("CASTLE","NORTH COMPLEX","AUGUST COMPLEX FIRES","CREEK")) %>%
  select(FIRE_NAME)

spots2 = st_intersection(spots %>%st_transform(st_crs(fires)),fires)

spots2 = spots2 %>%
  mutate(prog_shape = recode(prog_cat,
                             
                             "4" = "hexagon",
                             "3" = "pentagon",
                             "2" = "square",
                             "1" = "triangle",

                            
                             ),
         temp_color = recode(temp_cat,
                             "4" = "white",
                             "3" = "pink",
                             "2" = "purple",
                             "1" = "black")) %>%
  mutate(prog_shape = factor(prog_shape,levels=c("triangle","square","pentagon","hexagon")),
         temp_color = factor(temp_color,levels=c("white","pink","purple","black"))) %>%
  mutate(FIRE_NAME = as.character(FIRE_NAME))

a = table(spots2$prog_shape,spots2$temp_color,spots2$FIRE_NAME)

sink(datadir("temp/spot_strat.txt"), type=c("output", "message"))
a
sink()








spots = st_read(datadir("focal_area/manual_scouted_transition_spots_v2.gpkg"))

fires = st_read(datadir("fire_perims/DRAFT_Wildfire_Perimeters_2020_DRAFT.gpkg")) %>%
  filter(FIRE_NAME %in% c("CASTLE","NORTH COMPLEX","AUGUST COMPLEX FIRES","CREEK")) %>%
  select(FIRE_NAME)

spots2 = st_intersection(spots %>%st_transform(st_crs(fires)),fires)

spots2 = spots2 %>%
  mutate(prog_shape = recode(prog_cat,
                             
                             "4" = "hexagon",
                             "3" = "pentagon",
                             "2" = "square",
                             "1" = "triangle",
                             
                             
  ),
  temp_color = recode(temp_cat,
                      "4" = "white",
                      "3" = "pink",
                      "2" = "purple",
                      "1" = "black")) %>%
  mutate(prog_shape = factor(prog_shape,levels=c("triangle","square","pentagon","hexagon")),
         temp_color = factor(temp_color,levels=c("white","pink","purple","black"))) %>%
  mutate(FIRE_NAME = as.character(FIRE_NAME))

a = table(spots2$temp_color,spots2$FIRE_NAME)







