library(here)
library(sf)
library(tidyverse)
#library(stars)
library(terra)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))

spots = st_read(datadir("focal_area_2022/dixie-selected-for-crew/crew-spots.gpkg"))

# sort by cluster, priority
spots = spots %>%
  arrange(cluster, priority) %>%


# give unique ID number
  mutate(idnum = 1:nrow(spots) %>% str_pad(width=2,side="left",pad="0")) %>%

# prepend the spot type (S or C); make that the Name
  mutate(Name = paste0(toupper(type),idnum)) %>%
  
# order the attributes Name, cluster, priority, instructions, notes
  select(Name,cluster,priority,type,instructions,notes)
  
# save to separate S and C KMLs
st_write(spots %>% filter(type=="c"), datadir("focal_area_2022/dixie-selected-for-crew/named/dixie-spots-core.kml"), delete_dsn = TRUE)
st_write(spots %>% filter(type=="s"), datadir("focal_area_2022/dixie-selected-for-crew/named/dixie-spots-seedwall.kml"), delete_dsn = TRUE)

st_write(spots %>% filter(type=="c", priority=="1"), datadir("focal_area_2022/dixie-selected-for-crew/named/dixie-spots-core-p1.kml"), delete_dsn = TRUE)
st_write(spots %>% filter(type=="s", priority=="1"), datadir("focal_area_2022/dixie-selected-for-crew/named/dixie-spots-seedwall-p1.kml"), delete_dsn = TRUE)

st_write(spots %>% filter(type=="c", priority=="2"), datadir("focal_area_2022/dixie-selected-for-crew/named/dixie-spots-core-p2.kml"), delete_dsn = TRUE)
st_write(spots %>% filter(type=="s", priority=="2"), datadir("focal_area_2022/dixie-selected-for-crew/named/dixie-spots-seedwall-p2.kml"), delete_dsn = TRUE)

# save the priority sheet
spots_nonsp = spots
st_geometry(spots_nonsp) = NULL
# write_csv(spots_nonsp,datadir("focal_area_2022/dixie-selected-for-crew/named/dixie-spots-proiritization.csv"))


# save drone spots
# buffer by 100 m
spots_drone = spots %>% filter(priority %in% c("1","2")) %>% st_transform(3310) %>% st_buffer(150)

spots_drone = spots_drone %>%
  mutate(area = st_area(spots_drone) %>% set_units("ha")) %>%
  select(Name,cluster,priority,area)

st_write(spots_drone %>% filter(Name != "C10"), datadir("focal_area_2022/dixie-selected-for-crew/named/dixie-spots-drone.kml"), delete_dsn = TRUE)

# save the priority sheet
spots_drone_nonsp = spots_drone
st_geometry(spots_drone_nonsp) = NULL
write_csv(spots_drone_nonsp,datadir("focal_area_2022/dixie-selected-for-crew/named/dixie-drone-spots-proiritization.csv"))



# get the plots unique IDs
plots = st_read(datadir("focal_area_2022/dixie-selected-for-crew/crew-plots.gpkg"))

plots = plots %>%
  mutate(Name = 1:nrow(plots) %>% str_pad(3,"left","0") %>% paste0(" ",notes)) %>%
  mutate(bn = (str_sub(notes,1,3) == "bn")) %>%
  select(Name, bn)

st_write(plots %>% filter(bn == TRUE), datadir("focal_area_2022/dixie-selected-for-crew/named/dixie-plots-bn.kml"), delete_dsn = TRUE)
st_write(plots %>% filter(bn == FALSE | is.na(bn)), datadir("focal_area_2022/dixie-selected-for-crew/named/dixie-plots-bk.kml"), delete_dsn = TRUE)


## Save camps KML

camps = st_read(datadir("focal_area_2022/dixie-selected-for-crew/crew-camps.gpkg"))

st_write(camps,datadir("focal_area_2022/dixie-selected-for-crew/crew-camps.kml"))
