library("caret")
library("readr")
library("dplyr")
library("tidyr")
library("lubridate")
library("doMC")
registerDoMC(cores = 16)

## Your netid
netid <- "mujingru" ############################# change this !!!!!!!!!!
Month <- 1
Cluster <- 4
k <- c(1,3) ################################## change this!!!!!!!!! try 2,3,4

## create folder
Result_Dir_True <- sprintf("/work/STAT/%s/Tune_Results/", netid)
dir.create(Result_Dir_True)

# Cluster ID
cluster_id <- paste0("Cluster_", Cluster)

# Data read folder
WD <- "/work/STAT/lyux/dmc2018/"
setwd(WD)
Data <- read_rds("Cache/Feb_alltrain_sub_prc_may15.rds")


# Data Preprocessing
# Eliminate 
# if(Month == 3){
#   Train <- Data %>% filter(date <= "2018-01-03")
#   Test <- Data %>% filter(date >= "2018-01-04", date<"2018-02-01")
# }else{
#   Train <- Data %>% filter(date <= "2018-01-03", date >= "2017-12-04")
#   Test <- Data %>% filter(date >= "2018-01-04", date<"2018-02-01")
# }

Train <- Data %>% filter(date >= "2018-01-01", date <= "2018-01-31")
Test <- Data %>% filter(date >= "2018-02-01")

Train <- Train[Train[,cluster_id] %in% k,] %>%
  select_if(function(col) is.numeric(col)) %>% select(-pid)
Test <- Test[Test[,cluster_id] %in% k,]

## delete columns with only one level
var.out <- names(Train)[apply(Train, 2, function(x) length(unique(x)) == 1)]
Train <- Train %>% select(-one_of(var.out))


method <- "xgbTree"
cvControl <- trainControl(method = "repeatedcv", repeats = 10, number = 10, allowParallel = TRUE)
Tune <- train(y = Train$units,
              x = Train %>% select(-units),
              method = method,
              family = "poisson",
              preProcess = c("center","scale"),
              tuneGrid = data.frame(
                expand.grid(nrounds = c(100,150),
                            max_depth = 3, eta= c(0.3, 0.4),
                            subsample= 0.7, 
                            gamma= 0, min_child_weight = 1, colsample_bytree= 1)),   
              trControl=cvControl, maximize = F)


Pred <- predict(Tune, newdata=Test)
Feb_results <- Test %>% select(pid, size, date) %>% mutate(pred.units = Pred)
write_rds(Feb_results, sprintf("%sFebPred%s_Month%s_C%s_%s.rds", Result_Dir_True,method, Month, Cluster, k))


# MSPE = mean((Pred-Test$units)^2,na.rm=TRUE)


sink(sprintf("%sTuneResults%s_Month%s_C%s_%s.txt", Result_Dir_True, method,Month, Cluster, k))
# sprintf("Prediction Error: %.5f", MSPE)
cat("BestTune:", fill = T)
print(Tune$results %>% filter(RMSE == min(RMSE)))
cat("TuneResults:", fill = T)
print(Tune$results)
sink()



