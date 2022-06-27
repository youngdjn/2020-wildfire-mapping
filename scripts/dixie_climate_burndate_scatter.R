library(here)
library(sf)
library(tidyverse)
#library(stars)
library(terra)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))


foc = st_read(datadir("temp/focal_dixie.gpkg")) %>% st_union


# make grid of points in focal area

pts = st_make_grid(foc,cellsize=100,what="centers")
intersects = st_intersects(pts,foc, sparse=FALSE)

pts = pts[intersects[,1]]


# load fire progression
prog = 



# load elevation


# load precip