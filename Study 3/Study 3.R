library("readxl")
library(ggplot2)
library(dplyr)
library(tidyr)
library(openxlsx)
library(CORElearn)

# ============================================================================================================
##Reading Data
# ============================================================================================================

datao <-
  read.csv(
    "C:/Users/stewi_000/Desktop/Litkey Projekt/Results/CTAP Analyse/data for R/ORIG_data.csv"
  )


data_zielhyp <-
  read.csv(
    "C:/Users/stewi_000/Desktop/Litkey Projekt/Results/CTAP Analyse/data for R/ZIELHYP_data.csv"
  )


# ============================================================================================================
## Preprocessing
# ============================================================================================================

datao$Place <- recode(datao$Place, haus_orig.txt = "haus")


# recode Arab and Eu Plot by group and Language
datao$Student_Language <-
  dplyr::recode(
    datao$Student_Language,
    gr = "eu",
    bul = "eu",
    it = "eu",
    maz = "eu",
    per = "ar",
    en = "eu"
  )

#recode place variables
#datao$Place <- dplyr::recode(datao$Place, haus_orig.txt = "haus")

# NAs  (delete features)
dataNA <- datao[(is.na(datao$Value)), ]
dataNAlist <- table(dataNA$Feature_Name)
# Remove features that are missing in more than 90 texts out of 116 or more.
delete_features <- dataNAlist[dataNAlist > 90]
delete_features <- as.data.frame(delete_features)$Var1


#update the data frame (delete unnesessary features)
datao <- subset(datao,!datao$Feature_Name %in% delete_features)
length(unique(datao$Feature_Name))  # 495

df_min_value <-
  as.data.frame(aggregate(
    datao$Value,
    by = list(datao$Feature_id),
    min,
    na.rm = TRUE
  ))
df_max_value <-
  as.data.frame(aggregate(
    datao$Value,
    by = list(datao$Feature_id),
    max,
    na.rm = TRUE
  ))
df_merge_value <-
  merge(df_max_value,
        df_min_value,
        by = 'Group.1',
        suffixes = c('_max', '_min'))

#find the difference between min and max values
df_merge_value$diff_value <-
  df_merge_value$x_max - df_merge_value$x_min
df_merge_value <- df_merge_value[order(df_merge_value$diff_value), ]

#Check if features are variable and remove non-variable features
Feature_id_with_null_value <-
  df_merge_value[df_merge_value$diff_value < 0.0005,]$Group.1
# Update the dataset
datao <-
  subset(datao,!datao$Feature_id %in% Feature_id_with_null_value)
length(unique(datao$Feature_Name)) # 465


# scale
datao <-
  datao %>% group_by(Feature_Name) %>% mutate(Value = scale(Value))

data_zielhyp <-
  data_zielhyp %>% group_by(Feature_Name) %>% mutate(Value = scale(Value))

# recode Arab and Eu Plot by group and Language
data_zielhyp$Student_Language <-
  dplyr::recode(
    data_zielhyp$Student_Language,
    gr = "eu",
    bul = "eu",
    it = "eu",
    maz = "eu",
    per = "ar",
    en = "eu"
  )


# NAs  (delete features)
dataNA <- data_zielhyp[(is.na(data_zielhyp$Value)), ]
dataNAlist <- table(dataNA$Feature_Name)
# Remove features that are missing in more than 90 texts out of 116 or more.
delete_features <- dataNAlist[dataNAlist > 90]
delete_features <- as.data.frame(delete_features)$Var1
#update the data frame (delete unnesessary features)
data_zielhyp <-
  subset(data_zielhyp,!data_zielhyp$Feature_Name %in% delete_features)
length(unique(data_zielhyp$Feature_Name))  # 495

df_min_value <-
  as.data.frame(aggregate(
    data_zielhyp$Value,
    by = list(data_zielhyp$Feature_id),
    min,
    na.rm = TRUE
  ))
df_max_value <-
  as.data.frame(aggregate(
    data_zielhyp$Value,
    by = list(data_zielhyp$Feature_id),
    max,
    na.rm = TRUE
  ))
df_merge_value <-
  merge(df_max_value,
        df_min_value,
        by = 'Group.1',
        suffixes = c('_max', '_min'))

#find the difference between min and max values
df_merge_value$diff_value <-
  df_merge_value$V1_max - df_merge_value$V1_min
df_merge_value <- df_merge_value[order(df_merge_value$diff_value), ]

#Check if features are variable and remove non-variable features
Feature_id_with_null_value <-
  df_merge_value[df_merge_value$diff_value < 0.0005,]$Group.1
# Update the dataset
data_zielhyp <-
  subset(data_zielhyp,
         !data_zielhyp$Feature_id %in% Feature_id_with_null_value)
length(unique(data_zielhyp$Feature_Name)) # 465

data_zielhyp$Place <-
  recode(data_zielhyp$Place, haus_orig.txt = "haus")

# scale
data_zielhyp <-
  data_zielhyp %>% group_by(Feature_Name) %>% mutate(Value = scale(Value))

# ============================================================================================================
##RMSD calculation
# ============================================================================================================

datao$Text_num <- substr(datao$Text_Title, 6, 10)
data_zielhyp$Text_num <- substr(data_zielhyp$Text_Title, 6, 10)

rmsd_list <- c()
for (feat in unique(datao$Feature_Name)) {
  expected_list <- c()
  obs_list <- c()
  for (num in unique(datao$Text_num)) {
    expected = data_zielhyp[data_zielhyp$Text_num == num &
                              data_zielhyp$Feature_Name == feat,]$Value
    observed = datao[datao$Text_num == num &
                       datao$Feature_Name == feat,]$Value
    expected_list <- append(expected_list, expected)
    obs_list <- append(obs_list, observed)
  }
  
  dif = expected_list - obs_list
  rmsd = sqrt((sum(dif, na.rm = T) ** 2) / length(expected_list))
  rmsd_list <- append(rmsd_list, rmsd)
}

df_rmsd <- data.frame(unique(datao$Feature_Name), rmsd_list)


df_rmsd$rmsd_list <- round(df_rmsd$rmsd_list, digits = 2)
names(df_rmsd)[names(df_rmsd) == "unique.datao.Feature_Name."] <-
  "Feature_Name"

df_rmsd <- annnotate.feature.groups(df_rmsd)

write.xlsx(
  df_rmsd,
  file = tempfile(fileext = "rmsd_with_correlated.csv"),
  col_names = TRUE
)