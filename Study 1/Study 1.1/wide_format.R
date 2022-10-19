
library(ggplot2)
library(dplyr)
library(tidyr)
library(openxlsx)
library(CORElearn)
length(unique(datao$Feature_Name))

# ============================================================================================================
##Reading Data
# ============================================================================================================

datao <-
  read.csv(
    "C:/Users/stewi_000/Desktop/Litkey Projekt/Results/CTAP Analyse/data for R/ORIG_data.csv"
  )


# ============================================================================================================
## To Long Format
# ============================================================================================================

df_Feat_Story <- as.data.frame(matrix(-1, ncol=length(unique(datao$Feature_Name)),
                                      nrow = length(unique(datao$Story_ID))))

colnames(df_Feat_Story) <- unique(datao$Feature_Name)
rownames(df_Feat_Story) <- unique(datao$Story_ID)
df_Feat_Story

for( f in unique(datao$Feature_Name)){
  for(story in unique(datao$Story_ID)){
    val <- mean(datao[datao$Feature_Name == f & datao$Story_ID == story, ]$Value, na.rm = TRUE)
    df_Feat_Story[story, f] <- val
  }
}

df_Feat_Story <- df_Feat_Story[order(as.numeric(rownames(df_Feat_Story))),,drop=TRUE]
write.csv(df_Feat_Story, file = 'df_Feat_Story.csv', row.names = F,sep = ',')


df.datao.wide <- datao %>% pivot_wider(names_from = "Feature_Name", values_from = "Value")
df.datao.wide$Tags <- NULL
df.datao.wide$Text_Title <- NULL

write.csv(df.datao.wide, file = 'wide_format.csv')

