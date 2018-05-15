## LLR factor selection by Yuchen
rm(list = ls(all = T))
library(dplyr)
library(readr)
LLR_selection <- read.csv("../yuchenw2015/LLR_selection.csv", header = F)
(names.llr <- LLR_selection %>% unlist %>% unname %>% as.character())
filetonodummy <- "/vol/data/zhuz/lyux/feature_rds/item_static_features_may10.rds"
items <- read_rds(filetonodummy)
which(!names.llr %in% names(items))
LLR_fct <- items %>% dplyr::select(one_of(c("pid", "size", names.llr))) %>% 
  mutate(key = paste(pid, size, sep = " - "))
LLR_fct %>% glimpse

## Cluster group by hengfang
cluster_hf <- read_rds("../hengfang/cluster_2_9_freq_4.rds")
cluster_hf <- cluster_hf %>% mutate_all(as.character)
cluster_hf %>% glimpse
all(cluster_hf$key %in% LLR_fct$key)
LLR_cluster <- left_join(LLR_fct, cluster_hf, by = "key") %>% select(-key) %>%
  mutate(pid = as.numeric(pid))
LLR_cluster %>% glimpse

## alltrain with selected features by Xgboost and randomForest
filetopath <- "/vol/data/zhuz/lyux/feature_rds/alltrain_subfeatures_may14.rds"
alltrain_sub <- readr::read_rds(filetopath)
alltrain_sub %>% glimpse

alltrain_LLR <- left_join(alltrain_sub, LLR_cluster, by = c("pid", "size"))
glimpse(alltrain_LLR)

write_rds(alltrain_LLR, "/vol/data/zhuz/lyux/feature_rds/LLR_alltrain_subfeatures_may14.rds")

## Geometric Response Features
rm(list = ls(all = T))
Geo_response <- read.table("~/dmc_2018/Response.txt", header = T)
Geo_response <- Geo_response %>% rename(date = Day, response = Sold) %>%
  mutate(size = replace(size, size == "", "42"), date = ymd(date))
Geo_response %>% glimpse

pathtofile <- "/vol/data/zhuz/lyux/feature_rds/LLR_alltrain_subfeatures_may14.rds"
LLR_alltrain <- read_rds(pathtofile)
anti_join(Geo_response, LLR_alltrain, by = c("pid", "size", "date")) %>% dim

Geo_LLR_alltrain <- left_join(Geo_response, LLR_alltrain, by = c("pid", "size", "date"))
Geo_LLR_alltrain %>% glimpse

write_rds(Geo_LLR_alltrain %>% select(-units) %>% filter(!is.na(Cluster_2)),
          "/vol/data/zhuz/lyux/feature_rds/Geo_LLR_alltrain_subfeatures_may14.rds")

## model units for python
rm(list = ls(all = T))
alltrain_LLR <- read_rds("/vol/data/zhuz/lyux/feature_rds/LLR_alltrain_subfeatures_may14.rds")
alltrain_freq4 <- alltrain_LLR %>% filter(!is.na(Cluster_2)) %>%
  select(pid:date, Cluster_2:Cluster_9, units:trend.clearance)
any(is.na(alltrain_freq4))
write.table(alltrain_freq4, "/vol/data/zhuz/lyux/feature_rds/alltrain_freq4_subfeatures_may14.txt",
            quote = F, row.names = F, sep = "|")
names(alltrain_freq4) %>% sort