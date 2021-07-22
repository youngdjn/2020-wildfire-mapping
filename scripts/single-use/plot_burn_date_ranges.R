library(here)
library(tidyverse)

# The root of the data directory
data_dir = readLines(here("data_dir.txt"), n=1)
# Convenience functions, including function datadir() to prepend data directory to a relative path
source(here("scripts/convenience_functions.R"))

d = read_csv(datadir("focal_area/fire_selection/fire_burn_date_table.csv"))

todate = function(x) {
  as.Date(x,origin="2021-01-01")
}


d = d %>%
  mutate(across(c(point,min,max,outlier),todate))


ggplot(d,aes(x=point,y=fire)) +
  geom_point() +
       geom_errorbarh(aes(xmin=min,xmax=max),height=0) +
  geom_point(aes(x=outlier)) +
  theme_bw(20) +
  labs(x="burn date")
       