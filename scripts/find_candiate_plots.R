library(here)
library(sf)
library(tidyverse)
library(raster)
#library(stars)
library(terra)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))

fires = st_read(datadir("fire_perims/DRAFT_Wildfire_Perimeters_2020_DRAFT.gdb"))

eveg_raster = rast(datadir("eveg/ypmc_rasterized.tif"))

fires = fires %>%
  filter(GIS_ACRES> 50000) %>%
  st_transform(3310) %>%
  st_buffer(1) %>%
  dplyr::select(FIRE_NAME)

if(!file.exists(datadir("focal_area/plot_grid_unfiltered.gpkg"))) {
  #make point grid, fire by fire
  grid = NULL
  for(i in 1:nrow(fires)) {
    
    fire = fires[i,]
    
    temp = st_make_grid(fire,cellsize=100,what="centers") %>% st_as_sf
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
  
  st_write(grid,datadir("focal_area/plot_grid_unfiltered.gpkg"))
} else {
  grid = st_read(datadir("focal_area/plot_grid_unfiltered.gpkg"))
}

full_grid = grid

grid = full_grid[sample(1:nrow(full_grid),2000),]

grid1 = as(grid,"Spatial")
grid2 = 

ypmc = extract(eveg_raster,grid)

grid$ypmc = ypmc

st_write(grid,"test_grid.gpkg")
