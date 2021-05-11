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

fires = st_read(datadir("fire_perims/DRAFT_Wildfire_Perimeters_2020_DRAFT.gdb"))

# ownership
#fsland = st_read(datadir("ownership/fsland_ca.gpkg"))
ownership = st_read(datadir("ownership/California_Land_Ownership/California_Land_Ownership.shp")) %>%
  mutate(owner = recode(OWN_AGENCY,
                        "California Department of Parks and Recreation" = "state_park",
                        "USDA Forest Service" = "fs",
                        "Bureau of Land Management" = "blm",
                        "National Park Service" = "nps",
                        "California Department of Forestry and Fire Protection" = "calfire",
                        "University of California" = "uc")) %>%
  #filter(owner %in% c("state_park","fs","blm","nps","calfire","uc")) %>%
  dplyr::select(owner)

# Low-severity mainland
lowsev_mainland = st_read(datadir("fire_severity/near_lots_sev_under4.gpkg"))


cwhrtype = rast(datadir("eveg/cwhrtype_rasterized.tif"))
ypmc = rast(datadir("eveg/ypmc_rasterized.tif"))
dfr = rast(datadir("eveg/ypmc_rasterized.tif"))
mch = rast(datadir("eveg/ypmc_rasterized.tif"))
firesev = rast(datadir("fire_severity/ravg_2020_ba7_20210112.tif"))
temperature = rast(datadir("bcm/bcm_tmean_annual_normal.tif"))
slope = rast(datadir("dem/CAmerged14_albers_slope.tif"))
progression = rast(datadir("fire_progressions/2020_combined.tif"))


fires = fires %>%
  filter(GIS_ACRES> 50000) %>%
  st_transform(3310) %>%
  st_buffer(1) %>%
  dplyr::select(FIRE_NAME)

if(!file.exists(datadir("focal_area/plot_grid_dense_unfiltered.gpkg"))) {
  #make point grid, fire by fire
  grid = NULL
  for(i in 1:nrow(fires)) {
    
    fire = fires[i,]
    
    temp = st_make_grid(fire,cellsize=50,what="centers") %>% st_as_sf
    # grids[[i]] = st_intersection(grids[[i]],fires[i,],left=FALSE)
    
    # clip to fire
    temp = st_join(temp,fire)
    
    grid[[i]] = temp
    
    # if(is.null(grid)) {
    #   grid = temp
    # } else {
    #   grid = rbind(grid,temp)
    # }
  }
  
  a = do.call("rbind",grid)
  grid = a
  # grid = bind_rows(grids)
  
  grid = grid %>%
    filter(!is.na(FIRE_NAME))
  
  st_write(grid,datadir("focal_area/plot_grid_dense_unfiltered.gpkg"))
} else {
  grid = st_read(datadir("focal_area/plot_grid_dense_unfiltered.gpkg"))
}

full_grid = grid
grid = full_grid #grid = full_grid[sample(1:nrow(full_grid),2000),]
grid = vect(grid)

# do all raster extractions

grid = project(grid,firesev)
grid$firesev = extract(firesev,grid)[,2]
grid = grid[!is.nan(grid$firesev),]

grid = project(grid,cwhrtype)
grid$cwhrtype = extract(cwhrtype,grid)[,2]
grid = grid[!is.nan(grid$cwhrtype),]

grid = project(grid,slope)
grid$slope = extract(slope,grid)[,2]

grid = project(grid,progression)
grid$progression = extract(progression,grid)[,2]

grid = project(grid,temperature)
grid$temperature = extract(temperature,grid,method="bilinear")[,2]


writeVector(grid,datadir("temp/temp_plotgrid.gpkg"),filetype="GPKG", overwrite=TRUE)

grid = st_read(datadir("temp/temp_plotgrid.gpkg"))
grid = st_transform(grid,st_crs(ownership))
grid = st_join(grid,ownership)
grid = grid %>%
  filter(!is.na(owner))


## recode calveg
cwhrtype_crosswalk = read_csv(datadir("eveg/cwhrtype_lookup_table.csv"))
grid = left_join(grid,cwhrtype_crosswalk,by=c("cwhrtype"="cwhr_code"))

ypmc_types = c("DFR","EPN","JPN","MHC","PPN","SMC","WFR","KMC")
dfr_types = c("DFR")
mch_types = c("MCH","MCP")
focal_types = c(ypmc_types,dfr_types,mch_types)

grid = grid %>%
  mutate(ypmc = CWHR_TYPE %in% ypmc_types,
         dfr = CWHR_TYPE %in% dfr_types,
         mch = CWHR_TYPE %in% mch_types) %>%
  filter(CWHR_TYPE %in% focal_types)


## filter by slope
grid = grid %>%
  filter(slope < 30)

## filter by firesev
grid = grid %>%
  filter(firesev > 2)

# filter by low-severity mainland
st_write(lowsev_mainland,datadir("temp/tmp_lowsev_mainland2"),driver="ESRI Shapefile",append=FALSE)
lowsev_mainland = st_read(datadir("temp/tmp_lowsev_mainland2"))
lowsev_mainland = lowsev_mainland %>%
  mutate(lowsev_mainland = 1) %>%
  dplyr::select(lowsev_mainland)
grid = st_join(grid %>% st_transform(st_crs(lowsev_mainland)),lowsev_mainland)
grid = grid %>%
  filter(is.na(lowsev_mainland))



## they are no match if they are non-fs, non-calfire, chaparral
grid = grid %>%
  mutate(goodmatch = (!(mch == TRUE)) & (owner %in% c("blm","fs","calfire")))



st_write(grid,datadir("focal_area/candidate_grid_dense.gpkg"),append=FALSE)
