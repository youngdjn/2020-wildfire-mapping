library(here)
library(sf)
library(tidyverse)
#library(stars)
library(terra)

n# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))


foc = st_read(datadir("temp/focal_dixie.gpkg")) %>% st_union


# make grid of points in focal area

pts = st_make_grid(foc,cellsize=100,what="centers")
intersects = st_intersects(pts,foc, sparse=FALSE)

pts = pts[intersects[,1]]
pts = st_as_sf(pts)

# load fire progression
prog = rast(datadir("fire_progressions_2021/Dixie/Dixie_dob.tif"))

# load elevation
elev = rast(datadir("dem/CAmerged15_albers.tif"))

# load temp/precip
tmean = rast(datadir("prism/tmean_normal/PRISM_tmean_30yr_normal_800mM2_annual_bil.bil"))
ppt = rast(datadir("prism/ppt_normal/PRISM_ppt_30yr_normal_800mM3_annual_bil.bil"))

## at the points, extract progression, elev, tmean, ppt

pts$prog = extract(prog,vect(pts))[,2]
pts$elev = extract(elev,vect(pts), method="bilinear")[,2]
pts$tmean = extract(tmean,vect(pts %>% st_transform(st_crs(ppt))), method="bilinear")[,2]
pts$ppt = extract(ppt,vect(pts %>% st_transform(st_crs(ppt))), method="bilinear")[,2]


# set focal elev
pts = pts %>%
  mutate(focal_elev = between(elev,1850, 2050),
         focal_ppt_dry = between(ppt, 750,1000),
         focal_ppt_wet = between(ppt, 1300, 1700),
         focal_ppt_mid = between(ppt, 1000, 1600),
         focal_ppt_early_high = between(ppt, 1250,1850),
         focal_ppt_early_low = between(ppt,800,1400),
         focal_elev_early = between(elev,1600,2000),
         focal_tmean = between(tmean,6.5,8.5))

ggplot(pts, aes(x=prog, y=elev, color=focal_ppt_early_high)) +
  geom_point(size=.5) +
  theme_bw(8)


### IMP: need to check for intact pre-fire forest under the DOB gradient
### older NOTE that what we want is a focal elevation and ppt that stretch from earliest to ~230.
##xxxx Need to see what (if any) is accessible from day 200 or earlier -- nothing
## are there two parallel climate zones that go from day 200 to 230?



# want prog <= 200, tmean < 10

st_write(pts %>% filter(focal_elev), datadir("focal_area_2022/dixie_focal_elev.gpkg"), delete_dsn=TRUE)
st_write(pts %>% filter(focal_ppt_dry), datadir("focal_area_2022/dixie_focal_ppt_dry.gpkg"), delete_dsn=TRUE)
st_write(pts %>% filter(focal_ppt_wet), datadir("focal_area_2022/dixie_focal_ppt_wet.gpkg"), delete_dsn=TRUE)
st_write(pts %>% filter(focal_tmean), datadir("focal_area_2022/dixie_focal_tmean.gpkg"), delete_dsn=TRUE)
st_write(pts %>% filter(focal_ppt_mid & focal_tmean), datadir("focal_area_2022/dixie_focal_tmean_ppt-mid.gpkg"), delete_dsn=TRUE)
st_write(pts %>% filter(focal_ppt_mid & focal_elev), datadir("focal_area_2022/dixie_focal_elev_ppt-mid.gpkg"), delete_dsn=TRUE)
st_write(pts %>% filter(focal_ppt_early_high & between(elev,1500,2100)), datadir("focal_area_2022/dixie_focal_elev_ppt_high-early.gpkg"), delete_dsn=TRUE)
st_write(pts %>% filter(focal_ppt_early_low & between(elev,1200,1700)), datadir("focal_area_2022/dixie_focal_elev_ppt_low-early.gpkg"), delete_dsn=TRUE)
st_write(pts %>% filter(focal_ppt_early_low & between(elev,1500,2000)), datadir("focal_area_2022/dixie_focal_elev_ppt_low-early-alt.gpkg"), delete_dsn=TRUE)

## finish checking elev range for high percip

st_write(pts %>% filter(prog <= 200 & tmean < 10), datadir("focal_area_2022/dixie_earliest.gpkg"), delete_dsn=TRUE)

