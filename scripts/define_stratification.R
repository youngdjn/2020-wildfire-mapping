library(here)
library(sf)
library(tidyverse)
library(terra)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))


## Open the grid. Filter to focal fires, YPMC (incl WF), USFS. Cut dates in thirds. Cut temperature in thirds?

grid = st_read(datadir("focal_area/candidate_grid_dense.gpkg"))

grid = grid %>%
  filter(FIRE_NAME %in% c("NORTH COMPLEX","CASTLE","CREEK","AUGUST COMPLEX FIRES"),
         owner %in% "fs",
         CWHR_TYPE %in% c("PPN","JPN","KMC","SMC","WFR")) %>%
  mutate(date = as.Date(progression,origin="2019-12-31"))

ggplot(grid,aes(x=date,y=temperature)) +
  geom_point() +
  scale_x_date(date_labels= "%d-%b") #  limits = c(as.Date("2020-8-17"),as.Date("2020-10-16"))


hist(grid$progression)

# progression: 230 to 290 : 60/4
# temperature: 5.5 to 16

# stratification implemented here
grid_strat = grid %>%
  filter(!is.na(progression)) %>%
  mutate(prog_cat = cut(progression,breaks=c(0,242,256,270,500)) %>% as.numeric,
         temp_cat = cut(temperature,breaks=c(0,8.5,10.5,12.5,500)) %>% as.numeric) %>%
  mutate(prog_temp_cat = paste(prog_cat,temp_cat,sep="_"))

d_plot = grid_strat
st_geometry(d_plot) = NULL

## check it
ggplot(d_plot,aes(x=progression,y=temperature,color=prog_temp_cat)) +
  geom_point() +
  scale_color_viridis_d() +
  scale_x_continuous(n.breaks=10) +
  scale_y_continuous(n.breaks=10)
