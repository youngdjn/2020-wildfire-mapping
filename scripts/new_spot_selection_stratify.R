# stratify spots by temp and prog, make grid in spots


library(here)
library(sf)
library(tidyverse)
library(terra)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))


fires = st_read(datadir("fire_perims/DRAFT_Wildfire_Perimeters_2020_DRAFT.gpkg"))

fire_foc = fires %>%
  filter(FIRE_NAME == "CASTLE", REPORT_AC > 10000)
fire_foc = fires %>%
  filter(FIRE_NAME == "NORTH COMPLEX", REPORT_AC > 10000)
fire_foc = fires %>%
  filter(FIRE_NAME == "AUGUST COMPLEX FIRES")
fire_foc = fires %>%
  filter(FIRE_NAME == "CREEK", REPORT_AC > 10000)
fire_foc = st_read(datadir("fire_perims/manual_augustNE.gpkg")) %>% mutate(FIRE_NAME = "AUGUST_NE")


spots = st_read(datadir("focal_area/manual_scouted_spots_planet_augustNE.gpkg"))
spots = st_read(datadir("focal_area/manual_scouted_spots_planet_creek.gpkg"))  

#spots within focal fire only
spots_fire = st_intersection(spots %>% st_transform(3310),fire_foc %>% st_transform(3310))

spots_cent = st_centroid(spots_fire)
  
# get temperature and progression
## get temperature and progression at spots
temperature = rast(datadir("prism/tmean_normal/PRISM_tmean_30yr_normal_800mM2_annual_bil.bil"))
progression = rast(datadir("fire_progressions/2020_combined.tif"))

temperature_dat = extract(temperature,spots_cent %>% st_transform(crs(temperature))%>% vect)
spots_cent$temperature = temperature_dat[,2]

progression_dat = extract(progression,spots_cent %>% st_transform(crs(progression)) %>% vect)
spots_cent$progression = progression_dat[,2]

plot(temperature~progression,spots_cent)

#get centroid easting
spots_cent$easting = st_coordinates(spots_cent)[,1]


## merge centroid data back to the spots
spots_fire$easting = spots_cent$easting
spots_fire$temperature = spots_cent$temperature
spots_fire$progression = spots_cent$progression

## arrange the spots ascending eastward
spots_fire = spots_fire %>%
  arrange(easting)

## give them ID numbers
spots_fire$IDnum = 1:nrow(spots_fire) %>% str_pad(width = 3,side="left",pad="0")

## prepend ID numbers with F for Facserot or S for seedwall
spots_fire = spots_fire %>%
  mutate(prefix = recode(green_brown,
                         s = "S",
                         dm = "D",
                         b = "C",
                         g = "C",
                         gb = "C")) %>%
  mutate(Name = paste0(prefix,IDnum))

spots_cent = spots_fire %>% st_centroid()


## within each spot, make a grid of plots
allgrids = NULL
for(i in 1:nrow(spots_fire)) {
  spot = spots_fire[i,]
  if(spot$prefix == "D") next()
  cellsize = ifelse(spot$prefix == "S",20,50)
  grid = st_make_grid(spot,cellsize = cellsize,what = "centers") %>% st_as_sf
  grid = st_intersection(grid,spot) %>%
    select(green_brown,n_trees,FIRE_NAME,easting,temperature,progression,spot_IDnum = IDnum,prefix,spot_Name = Name,x)
  grid$xcoord = st_coordinates(grid)[,1]
  grid$ycoord = st_coordinates(grid)[,2]
  grid = grid %>% arrange(-ycoord,xcoord)
  grid$grid_IDnum = 1:nrow(grid)  %>% str_pad(width = 3,side="left",pad="0")
  allgrids = rbind(allgrids,grid)
}

allgrids = allgrids %>%
  mutate(Name = paste0(spot_Name,"-",grid_IDnum))

## assign colors to progression
# black, purple, pink, white
cut1 = min(spots_cent$progression)
cut4 = max(spots_cent$progression)
cutstep = (cut4-cut1)/4
cut2 = cut1+cutstep
cut3 = cut1+2*cutstep
cut4 = cut1+3*cutstep

spots_cent = spots_cent %>%
  mutate(prog_cat = cut(progression,breaks=c(0,cut2,cut3,cut4,1000),labels=c(1,2,3,4))) %>% #labels=c(1,2,3,4)
  mutate(prog_cat = ifelse(prefix %in% c("S") ,-1,prog_cat)) %>%
  mutate(prog_cat = ifelse(prefix %in% c("D") ,-2,prog_cat))


st_write(spots_cent,datadir("focal_area/new_spots_cent_creek.gpkg"),delete_dsn=TRUE)
st_write(spots_fire,datadir("focal_area/new_spots_poly_creek.gpkg"),delete_dsn=TRUE)
st_write(allgrids,datadir("focal_area/new_grid_creek.gpkg"),delete_dsn=TRUE)


  