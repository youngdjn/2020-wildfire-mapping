library(here)
library(sf)
library(tidyverse)
#library(stars)
library(terra)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))


# load eveg
eveg = rast(datadir("eveg/cwhrtype_rasterized.tif"))

# load perim
perim = st_read(datadir("fire_perims/ca3987612137920210714_20201012_20211015_ravg_data/ca3987612137920210714_20201012_20211015_burn_bndy.shp")) %>% st_union %>% st_buffer(0)
perim = st_read(datadir("fire_perims/ca3858612053820210815_20201011_20211016_ravg_data/ca3858612053820210815_20201011_20211016_burn_bndy.shp")) %>% st_union %>% st_buffer(0)

# load slope
slope = rast(datadir("dem/camerged14_albers_slope.tif"))

# load fs
nonfs = st_read(datadir("ownership/ca_non-fs_land.gpkg"))


# crop layers to perim
eveg_crop = crop(eveg,perim %>% st_transform(st_crs(eveg)))
slope_crop = crop(slope,perim %>% st_transform(st_crs(slope)))
nonfs = st_intersection(nonfs,perim %>% st_transform(st_crs(nonfs)))

# vectorize eveg
eveg_foc = eveg_crop == 3
eveg_coarse = aggregate(eveg_foc, fact=3, fun=mean)
eveg_coarse = eveg_coarse >= .50
eveg_vect = as.polygons(eveg_coarse) %>% project("epsg:3310")
eveg_sf = eveg_vect %>% st_as_sf() %>% filter(cwhrtype_rasterized == 0) %>% st_union()

# vectorize slope
slope_foc = slope_crop < 35


# keep only eveg foc type
perim = st_transform(perim,3310)
perim = st_set_precision(perim,unit(10,"cm"))
perim = st_buffer(perim,1)
eveg_sf = st_transform(eveg_sf,3310)
eveg_sf = st_set_precision(eveg_sf,unit(10,"cm"))
eveg_sf = st_union(eveg_sf)
#eveg_sf = st_buffer(eveg_sf,1)
perim2 = st_difference(st_make_valid(perim),st_make_valid(eveg_sf))

st_write(perim2,datadir("temp/perim2.gpkg"), delete_dsn=TRUE)

# keep only llow slope
slope_coarse = aggregate(slope_foc,fact=3,fun=mean)
slope_coarse = slope_coarse >= 0.5
slope_vect = as.polygons(slope_coarse) %>% project("epsg:3310")
slope_sf = slope_vect %>% st_as_sf() %>% filter(CAmerged14_albers_slope == 0) %>% st_union()

perim4 = st_difference(st_make_valid(perim2),st_make_valid(slope_sf))

st_write(perim4,datadir("temp/perim4.gpkg"), delete_dsn=TRUE)


# buffer by 65 m (so we smooth over some bad pixels)

perim5 = st_buffer(perim4, 65)
st_write(perim5,datadir("temp/perim5.gpkg"), delete_dsn=TRUE)

# remove nonfs land
perim5 = st_difference(perim5,nonfs %>% st_transform(st_crs(perim5)))



# remove areas that are less than 500x500 m

perim6 = perim5 %>% st_cast("POLYGON") %>% st_as_sf
perim6$area = st_area(perim6) %>% as.numeric
perim6 = perim6 %>% filter(area > 500*500)

# remove stringers

perim7 = perim6 %>% st_buffer(35)

perim7$perim = lwgeom::st_perimeter(perim7) %>% as.numeric
perim7$perim_area_ratio = perim7$perim / perim7$area

perim6 = perim6[perim7$perim_area_ratio < .01,]

st_write(perim6,datadir("temp/focal_dixie.gpkg"), delete_dsn=TRUE)

# make a version that's the fire perim but inverse (to mask out where we don't want)

focal_neg_mask = st_difference(perim,perim6 %>% st_union)

st_write(focal_neg_mask,datadir("temp/focal_neg_mask_dixie.gpkg"), delete_dsn =TRUE)
