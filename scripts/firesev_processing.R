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

fires = st_read(datadir("fire_perims/DRAFT_Wildfire_Perimeters_2020_DRAFT.gdb")) %>%
  filter(GIS_ACRES > 10000)

foc_fire_names = c("CALDWELL", "NORTH COMPLEX","CASTLE","CREEK","AUGUST COMPLEX FIRES")
fires_foc = fires %>%
  filter(FIRE_NAME %in% foc_fire_names) %>%
  vect

firesev = rast(datadir("fire_severity/ravg_2020_ba7_20210112.tif"))


sev = crop(firesev,fires_foc %>% project(firesev))
sev = mask(sev,fires_foc %>% project(firesev))

sev_over4 = sev > 4
sev_under4 = sev < 4

# find where there's lots of lowsev
amt_sev_under4 = focal(sev_under4, w = 3, fun="sum")

#
lots_sev_under4 = amt_sev_under4 > 4
lots_sev_under4 = subst(lots_sev_under4,0,NA)

### get distance to where there's lots of lowsev
# need to do this fire by fire
allfires = NULL
for(i in 1:nrow(fires_foc)) {
  fire_foc = fires_foc[i,]
  
  sev_foc = crop(lots_sev_under4,fire_foc %>% project(lots_sev_under4))  
  near_lots_sev_under4 = as.polygons(sev_foc) %>% buffer(width=200)
  
  writeVector(near_lots_sev_under4, datadir("temp/temp.gpkg"),filetype="GPKG",overwrite=TRUE)
  near_lots_sev_under4 = st_read(datadir("temp/temp.gpkg"))
  
  allfires = rbind(allfires,near_lots_sev_under4)

}

st_write(allfires,datadir("fire_severity/near_lots_sev_under4.gpkg"), append=FALSE)



