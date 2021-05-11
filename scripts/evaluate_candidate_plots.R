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
  mutate(state_forest = ifelse(owner == "calfire",TRUE,FALSE)) %>%
  mutate(FIRE_NAME = recode(FIRE_NAME,
                            "AUGUST COMPLEX FIRES" = "August Complex",
                            "CASTLE" = "Castle",
                            "CREEK" = "Creek",
                            "NORTH COMPLEX" = "North Complex"))

g = ggplot(d %>% filter(FIRE_NAME != "CALDWELL"),aes(x=date,y=temperature,color=FIRE_NAME)) +
  geom_jitter(size=0.5,width=0.5) +
  #facet_grid(~august_cplx) +
  theme_bw(18) +
  scale_color_viridis_d(name="Fire") +
  scale_x_date(date_labels= "%d-%b", limits = c(as.Date("2020-8-17"),as.Date("2020-10-16"))) +
  #geom_point(data=d %>% filter(owner == "calfire"),size=4,color="red")
  labs(x = "Burn date", y = "Mean annual temperature (°C)") +
  guides(color = guide_legend(override.aes = list(size=2))) +
  theme(legend.position = c(.70,.87), legend.background = element_rect(fill=NA))

png(datadir("figures/temperature-vs-burndate.png"), width=800,height=1000,res=150)
g
dev.off()
