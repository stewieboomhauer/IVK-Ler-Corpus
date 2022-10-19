library(ggplot2)
library(dplyr)
library(tidyr)
library(readxl)
library(CORElearn)

# ============================================================================================================
##Reading Data
# ============================================================================================================
datao <-
  read.csv(
    "C:/Users/stewi_000/Desktop/Litkey Projekt/Results/CTAP Analyse/data for R/ORIG_data.csv"
  )

df.ig <- read_excel("C:/Users/stewi_000/Downloads/df.ig.xlsx")

df.ig.oneRattr <-
  read_excel("C:/Users/stewi_000/Downloads/rel_df_oneR1.xlsx")
df.ig.oneRattr <- annnotate.feature.groups(df.ig.oneRattr)
write_xlsx(df.ig.oneRattr,
           "C:/Users/stewi_000/Downloads/rel_df_ig2.xlsx")

# ============================================================================================================
## Preprocessing
# ============================================================================================================

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
datao$Place <- recode(datao$Place, haus_orig.txt = "haus")


# ============================================================================================================
# Annotate the feature groups based on the feature names.
# ============================================================================================================
annnotate.feature.groups <- function(df.orig) {
  df.rval <- df.orig %>%
    mutate(
      Feature_Group = case_when(
        grepl("Dependency Locality Theory", Feature_Name) ~ "Human processing",
        grepl("Lexical Richness", Feature_Name) ~ "Lexical Richness",
        grepl("Lexical diversity", Feature_Name) ~ "Lexical diversity",
        grepl("Lexical Variation", Feature_Name) ~ "Lexical diversity",
        grepl("Sentence (Length|T-unit|Clause)", Feature_Name) ~ "Clausal",
        grepl("Sentence Coordination Ratio", Feature_Name) ~ "Clausal",
        grepl("Mean Length of (.*T-unit|Clause)", Feature_Name) ~ "Clausal",
        grepl("Mean Sentence Length", Feature_Name) ~ "Clausal",
        grepl("Complex T-unit per Sentence", Feature_Name) ~ "Clausal",
        grepl("T-unit complexity ratio", Feature_Name) ~ "Clausal",
        grepl("Complex T-unit ratio", Feature_Name) ~ "Clausal",
        grepl("Relative Clauses per .*", Feature_Name) ~ "Clausal",
        grepl("Dependent clause ratio", Feature_Name) ~ "Clausal",
        grepl("Sentence Complexity Ratio", Feature_Name) ~ "Clausal",
        grepl("Coordinate Clauses per Clause", Feature_Name) ~ "Clausal",
        grepl("Dependent [Cc]lauses per .*", Feature_Name) ~ "Clausal",
        grepl("Complex T-unit Ratio", Feature_Name) ~ "Clausal",
        grepl("Mean Length of .* Phrase", Feature_Name) ~ "Phrasal",
        grepl("Complex .* Phrases per .*", Feature_Name) ~ "Phrasal",
        grepl(".* Phrases per .*", Feature_Name) ~ "Phrasal",
        grepl("Verb Cluster", Feature_Name) ~ "Phrasal",
        grepl("Complex Nominals per .*", Feature_Name) ~ "Phrasal",
        grepl(".* Modifier per Complex .* Phrase", Feature_Name) ~ "Phrasal",
        grepl(
          "POS Density Feature: ((Non )?3rd Person Singular|Base Form|Past Tense|Modal|Gerund|Past Participle|Auxiliary|(In)?[fF]inite) Word",
          Feature_Name
        ) ~ "Lexical Density",
        grepl("POS Density Feature: Modals per (Word|Verb)", Feature_Name) ~ "Lexical Density",
        grepl("POS Density Feature: Possessive Ending", Feature_Name) ~ "Lexical Density",
        grepl(
          "POS Density Feature: (Comparative Adjective|Adjective JJ)",
          Feature_Name
        ) ~ "Lexical Density",
        grepl(
          "POS Density Feature: Superlative (Adjective|Adverb)",
          Feature_Name
        ) ~ "Lexical Density",
        grepl("POS Density Feature: Adverb RB", Feature_Name) ~ "Lexical Density",
        grepl(
          "POS Density Feature: (Common )?((Singular|Plural) )?(Proper )?Noun",
          Feature_Name
        ) ~ "Lexical Density",
        grepl("POS Density Feature: Raw .* Count", Feature_Name) ~ "To be deleted",
        grepl("POS Density Feature:", Feature_Name) ~ "Lexical Density",
        grepl("Lexical Density Feature", Feature_Name) ~ "Lexical Density",
        grepl("Edit Distance", Feature_Name) ~ "Syntactic variation",
        grepl("Left Embeddedness", Feature_Name) ~ "Clausal",
        grepl("Lexical Sophistication", Feature_Name) ~ "Language use",
        grepl("Referential Cohesion", Feature_Name) ~ "Cohesion",
        grepl("Number of Connectives", Feature_Name) ~ "Cohesion",
        grepl("Cohesive Complexity", Feature_Name) ~ "Cohesion",
        grepl("Length in Tokens", Feature_Name) ~ "Length Measures",
        grepl("SD Sentence Length", Feature_Name) ~ "Length Measures",
        grepl("Token Length in", Feature_Name) ~ "Length Measures",
        grepl(
          "Number [oO]f (syllables|Letters|Tokens|Word|Unique|Sentences)",
          Feature_Name
        ) ~ "Length Measures",
        grepl(
          "(Number|Percentage) of .* with More Than 2 Syllables",
          Feature_Name
        ) ~ "Length Measures",
        grepl("Morphological Complexity", Feature_Name) ~ "Morphological complexity",
        grepl("Number of (POS|Syntactic)", Feature_Name) ~ "Raw counts",
        TRUE ~ NA_character_
      )
    ) %>%
    filter(!(Feature_Group %in% c("To be deleted", "Raw counts")))
  return(df.rval)
}


datao <- annnotate.feature.groups(datao)
length(unique(datao$Feature_Group))  # 11

# ============================================================================================================
# Delete correlated features
# ============================================================================================================
identify.relevant.features <-
  function(df.corr, df.ig, correlation.threshold = .8) {
    df.rval <- df.ig
    df.rval$Relevant <- FALSE
    df.rval$Banned <- FALSE
    
    for (f in df.rval$Feature_Name) {
      # skip features that are banned because they are highly correlated with more informative feature
      if (df.rval[df.rval$Feature_Name == f, ]$Banned) {
        next()
      }
      
      # flag feature as relevant
      df.rval[df.rval$Feature_Name == f, ]$Relevant <- TRUE
      # ban features that are highly correlated with this feature
      df.tmp <- df.corr %>%
        filter(row == f | column == f,
               abs(cor) >= correlation.threshold) %>%
        select(row, column)
      df.rval <- df.rval %>%
        mutate(
          Banned = if_else(
            Feature_Name %in% df.tmp$row & !Feature_Name == f,
            TRUE,
            Banned
          ),
          Banned = if_else(
            Feature_Name %in% df.tmp$column & !Feature_Name == f,
            TRUE,
            Banned
          )
        )
    }
    return(df.rval)
  }

testGroup <-
  aggregate(
    datao$Value,
    by = list(datao$Feature_Name, datao$Story_ID),
    mean,
    na.rm = T
  )
df_corr <-
  as.data.frame(matrix(0, ncol = length(unique(testGroup$Group.1)), nrow =
                         length(unique(testGroup$Group.2))))
colnames(df_corr) <- unique(testGroup$Group.1)
rownames(df_corr) <- unique(testGroup$Group.2)

for (feature in unique(testGroup$Group.1)) {
  for (story in unique(testGroup$Group.2)) {
    current_value = testGroup[testGroup$Group.1 == feature &
                                testGroup$Group.2 == story,]$V1
    df_corr[story, feature] = current_value
  }
}

cor_table <- as.data.frame(cor(df_corr))

library(Hmisc)
res2 <- rcorr(as.matrix(cor_table))

flattenCorrMatrix <- function(cormat, pmat) {
  ut <- upper.tri(cormat)
  data.frame(
    row = rownames(cormat)[row(cormat)[ut]],
    column = rownames(cormat)[col(cormat)[ut]],
    cor  = (cormat)[ut],
    p = pmat[ut]
  )
}

#Create correlation Matrix
cor_df <- flattenCorrMatrix(res2$r, res2$P)


datao_corr_df <- identify.relevant.features(cor_df, df.ig., 0.6)
datao_corr_df_oneR <-
  identify.relevant.features(cor_df, df.ig.oneRattr, 0.8)

rel_df <- datao_corr_df[datao_corr_df$Relevant == T, ]

library("writexl")
write_xlsx(rel_df, "C:/Users/stewi_000/Downloads/rel_df_ig.xlsx")

rel_df_oneR <- datao_corr_df_oneR[datao_corr_df_oneR$Relevant == T, ]
rel_df_oneR <- annnotate.feature.groups(rel_df_oneR)
write_xlsx(rel_df_oneR,
           "C:/Users/stewi_000/Downloads/rel_df_oneR.xlsx")

most_features <-
  rel_df[order(rel_df$`average merit`, decreasing = TRUE), ]$Feature_Name[1:20]
most_features_oneR <-
  rel_df_oneR[order(rel_df_oneR$`average merit`, decreasing = TRUE), ]$Feature_Name[1:20]

most_features_oneR <- df.ig.oneRattr$Feature_Name[1:20]
most_features_oneR
need_student

datao_result_f <- datao[datao$Feature_Name %in% most_features,]
datao_result_f_oneR <-
  datao[datao$Feature_Name %in% most_features_oneR,]

counts = datao_result_f[, c('Story_ID', 'Student_ID')] %>% group_by(Student_ID, Story_ID) %>% count()
counts1 = datao_result_f_oneR[, c('Story_ID', 'Student_ID')] %>% group_by(Student_ID, Story_ID) %>% count()

counts = counts1
need_student = names(table(counts$Student_ID))
need_student = as.integer(need_student)
need_student = need_student[table(counts$Student_ID) > 6]

need_student <- as.character(need_student)
datao_result_f <- datao_result_f[datao_result_f$Story_ID != 5, ]
datao_result_f$Student_ID <- as.character(datao_result_f$Student_ID)
datao_result_f <-
  datao_result_f[datao_result_f$Student_ID %in% need_student, ]

datao_result_f_oneR <-
  datao_result_f_oneR[datao_result_f_oneR$Story_ID != 5, ]
datao_result_f_oneR$Student_ID <-
  as.character(datao_result_f_oneR$Student_ID)
datao_result_f_oneR <-
  datao_result_f_oneR[datao_result_f_oneR$Student_ID %in% need_student, ]


datao_without_corr_f = datao_result_f_oneR
sum(unique(datao_without_corr_f$Text_id))
table(unique(datao_without_corr_f$Text_id))


# ============================================================================================================
#Student_ID
# ============================================================================================================
ggplot(data = datao_without_corr_f,
       aes(x = Story_ID, y = Value, color = Student_ID)) +
  geom_line() +
  #labs(title = paste('Feature: ',f))+
  scale_x_discrete(limits = c(1:4, 6:12)) +
  facet_wrap( ~ Feature_Name, ncol = 4) +
  theme(plot.title = element_text(size = 3))

# ============================================================================================================
#Student_Gender
# ============================================================================================================
ggplot(data = datao_without_corr_f,
       aes(
         x = Story_ID,
         y = Value,
         color = Student_Gender,
         group = Student_ID
       )) +
  geom_line() +
  labs(title = paste('Feature: ', f)) +
  scale_x_discrete(limits = c(1:4, 6:12)) +
  facet_wrap( ~ Feature_Name, ncol = 4) +
  theme(plot.title = element_text(size = 3))



# ============================================================================================================
#Student_Language
# ============================================================================================================
ggplot(data = datao_without_corr_f,
       aes(
         x = Story_ID,
         y = Value,
         color = Student_Language,
         group = Student_ID
       )) +
  geom_line() +
  #labs(title = paste('Feature: ',f))+
  scale_x_discrete(limits = c(1:4, 6:12)) +
  facet_wrap( ~ Feature_Name, ncol = 4) +
  theme(plot.title = element_text(size = 3))
