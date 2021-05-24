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


## exclude plots within 200 m of unmapped severity
unmapped = sev == 9
unmapped = subst(unmapped,FALSE,NA)
unmapped_poly = as.polygons(unmapped) %>% buffer(width=250)
writeVector(unmapped_poly, datadir("fire_severity/unmapped_severity"),filetype="ESRI Shapefile",overwrite=TRUE)


#sev_over4 = sev > 4
sev_under5 = sev <5
sev_0to2 = sev < 3
sev_67 = sev > 5

# find where there's lots of lowsev
amt_sev_under5 = focal(sev_under5, w = 11, fun="sum") # search radius = 30*13/2 = 195 m

amt_sev_0to2 = focal(sev_0to2, w = 11, fun="sum")
amt_sev_67 = focal(sev_67, w = 11, fun="sum")


#
lots_sev_under5 = amt_sev_under5 > (11^2 * .60) # at least 60% of the pixels within a 11 pixel window are not high sev
lots_sev_under5 = subst(lots_sev_under5,0,NA)

lots_sev_0to2 = amt_sev_0to2 > (11^2 * .90) # at least 60% of the pixels within a 11 pixel window are not high sev
lots_sev_0to2 = subst(lots_sev_0to2,0,NA)

lots_sev_67 = amt_sev_67 > (11^2 * .90) # at least 60% of the pixels within a 11 pixel window are not high sev
lots_sev_67 = subst(lots_sev_67,0,NA)

### get distance to where there's lots of lowsev
# need to do this fire by fire
allfires_sevunder5 = NULL
allfires_sev0to2 = NULL
allfires_sev67 = NULL
for(i in 1:nrow(fires_foc)) {
  fire_foc = fires_foc[i,]
  
  sev_foc = crop(lots_sev_under5,fire_foc %>% project(lots_sev_under5))  
  near_lots_sev_under5 = as.polygons(sev_foc) %>% buffer(width=250+30*11/2)  # the non-core area is 250 m + the search radius for non-high sev
  
  writeVector(near_lots_sev_under5, datadir("temp/temp.gpkg"),filetype="GPKG",overwrite=TRUE)
  near_lots_sev_under5 = st_read(datadir("temp/temp.gpkg"))
  
  allfires_sevunder5 = rbind(allfires_sevunder5,near_lots_sev_under5)
  
  
  # sev 0to2
  sev_foc = crop(lots_sev_0to2,fire_foc %>% project(lots_sev_0to2))  
  near_lots_sev_0to2 = as.polygons(sev_foc)# %>% buffer(width=30*11/2)  # the non-core area is 250 m + the search radius for non-high sev
  
  writeVector(near_lots_sev_0to2, datadir("temp/temp.gpkg"),filetype="GPKG",overwrite=TRUE)
  near_lots_sev_0to2 = st_read(datadir("temp/temp.gpkg"))
  
  allfires_sev0to2 = rbind(allfires_sev0to2,near_lots_sev_0to2)
  
  
  # sev 6,7
  sev_foc = crop(lots_sev_67,fire_foc %>% project(lots_sev_67))  
  near_lots_sev_67 = as.polygons(sev_foc)# %>% buffer(width=30*11/2)  # the non-core area is 250 m + the search radius for non-high sev
  
  writeVector(near_lots_sev_67, datadir("temp/temp.gpkg"),filetype="GPKG",overwrite=TRUE)
  near_lots_sev_67 = st_read(datadir("temp/temp.gpkg"))
  
  allfires_sev67 = rbind(allfires_sev67,near_lots_sev_67)

}

st_write(allfires_sevunder5,datadir("fire_severity/near_lots_sev_under5"), append=FALSE,driver="ESRI Shapefile")
st_write(allfires_sev0to2,datadir("fire_severity/near_lots_sev_0to2"), append=FALSE,driver="ESRI Shapefile")
st_write(allfires_sev67,datadir("fire_severity/near_lots_sev_67"), append=FALSE,driver="ESRI Shapefile")


## get low sev (or fire perim) next to high sev

#get buffered perim of focal fires
fires = st_read(datadir("fire_perims/DRAFT_Wildfire_Perimeters_2020_DRAFT.gdb")) %>%
  filter(GIS_ACRES > 10000)

foc_fire_names = c("CALDWELL", "NORTH COMPLEX","CASTLE","CREEK","AUGUST COMPLEX FIRES")
fires_foc2 = fires %>%
  filter(FIRE_NAME %in% foc_fire_names) %>%
  st_transform(3310)%>%
  st_buffer(1)

fires_foc_buff = fires_foc2 %>% st_buffer(100)
fires_foc_ring = gDifference(fires_foc_buff %>% as("Spatial"), fires_foc2 %>% as("Spatial")) %>% as("sf")

a = allfires_sev0to2 %>% st_transform(3310) %>% mutate(a = 1) %>% dplyr::select(a) %>%rename(geometry="geom")
b = fires_foc_ring %>% mutate(a = 1) %>% select(a)

lowsev = rbind(a,b)
st_write(lowsev,datadir("fire_severity/perim_and_near_lots_sev_0to2"),driver="ESRI Shapefile")
lowsev = st_read(datadir("fire_severity/perim_and_near_lots_sev_0to2"))

st_write(allfires_sev67,datadir("fire_severity/near_lots_highsev"),driver="ESRI Shapefile")
highsev = st_read(datadir("fire_severity/near_lots_highsev"))

lowsev_buff = lowsev %>% st_buffer(250)
highsev_buff = highsev %>% st_buffer(250) %>% st_transform(3310)

# get where they overlap
highsev_near_lowsev = st_intersection(highsev_buff,lowsev_buff) %>% st_buffer(300) %>% st_union

st_write(highsev_buff,datadir("temp/highsev_buff101.shp"))
st_write(lowsev_buff,datadir("temp/lowsev_buff101.shp"))


st_write(highsev_near_lowsev,datadir("fire_severity/highsev_lowsev_transition"),driver="ESRI Shapefile",append=FALSE)



