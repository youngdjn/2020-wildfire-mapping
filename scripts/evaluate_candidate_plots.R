library(here)
library(sf)
library(tidyverse)


# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))

plots = st_read(datadir("focal_area/candidate_grid_dense.gpkg"))

d = plots
st_geometry(d) = NULL

d = d[sample(1:nrow(d),replace = FALSE),]

# plot for august or other
d = d %>%
  filter(FIRE_NAME %in% c("AUGUST COMPLEX FIRES","CALDWELL","CASTLE","CREEK","NORTH COMPLEX")) %>%
  mutate(august_cplx = ifelse(FIRE_NAME == "AUGUST COMPLEX FIRES",TRUE,FALSE)) %>%
  filter(ypmc == TRUE) %>%
  mutate(date = as.Date(progression,origin="2019-12-31")) %>%
  mutate(state_forest = ifelse(owner == "calfire",TRUE,FALSE))

g = ggplot(d,aes(x=date,y=temperature,color=FIRE_NAME)) +
  geom_jitter(size=1,width=0.5) +
  facet_grid(~august_cplx) +
  theme_bw() +
  scale_color_viridis_d() +
  scale_x_date(date_labels= "%d-%b") +
  #geom_point(data=d %>% filter(owner == "calfire"),size=4,color="red")
  labs(x = "Burn date", y = "Mean annual temperature (°C)")

png(datadir("figures/temperature-vs-burndate_august-sep.png"), width=2000,height=1000,res=150)
g
dev.off()
