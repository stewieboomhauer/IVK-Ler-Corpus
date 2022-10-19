library(ggplot2)
library(dplyr)
library(tidyr)
library(openxlsx)
library(CORElearn)
library("readxl")
# xls files


# ============================================================================================================
##Reading Data
# ============================================================================================================
datao <-
  read.csv(
    "C:/Users/stewi_000/Desktop/Litkey Projekt/Results/CTAP Analyse/data for R/ORIG_data.csv"
  )

# ============================================================================================================
## Data Preprocessing
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



# ============================================================================================================
## Descriptive Statistics
# ============================================================================================================

# Get descriptive statistics about number of words and documents across languages

# Number of files
datao %>%
  filter(Feature_Name == "Lexical Richness: Type Token Ratio (TTR)")  %>%
  tally()


# Number of words
datao %>%
  filter(Feature_Name == "Number of Tokens") %>%
  summarize(
    Sum = sum(Value),
    Mu = mean(Value),
    Sd = sd(Value),
    M = median(Value),
    Min = min(Value),
    Max = max(Value)
  )


# Number of sentences
datao %>%
  filter(Feature_Name == "Number of Sentences")  %>%
  summarize(
    Sum = sum(Value),
    Mu = mean(Value),
    Sd = sd(Value),
    M = median(Value),
    Min = min(Value),
    Max = max(Value)
  )

# count unique students by Story_ID
g1 <-
  aggregate(
    datao$Student_ID,
    by = list(datao$Story_ID),
    FUN = function(x)
      length(unique(x))
  )

ggplot(g1, aes(x = as.factor(Group.1), y = x)) + ggtitle("Amount of unique students by Story_ID") + xlab("Story_ID") + ylab("Student") +
  geom_bar(stat = "identity")

# count unique students by sex
g2 <-
  aggregate(
    datao$Student_ID,
    by = list(datao$Story_ID, datao$Student_Gender),
    FUN = function(x)
      length(unique(x))
  )
g2 <- g2[order(g2$Group.1), ]
ggplot(g2, aes(
  x = as.factor(Group.1),
  y = x,
  fill = Group.2
)) + ggtitle("Amount of unique students by gender") + xlab("Gender") + ylab("Student") +
  geom_bar(stat = "identity", position = 'dodge')

# count unique students by language
g3 <-
  aggregate(
    datao$Student_ID,
    by = list(datao$Story_ID, datao$Student_Language),
    FUN = function(x)
      length(unique(x))
  )
g3 <- g3[order(g3$Group.1), ]
ggplot(g3, aes(
  x = as.factor(Group.1),
  y = x,
  fill = Group.2
)) + ggtitle("Amount of unique students by language") + xlab("Language") + ylab("Student") +
  geom_bar(stat = "identity", position = 'dodge')

# count unique students by Place
g4 <-
  aggregate(
    datao$Student_ID,
    by = list(datao$Story_ID, datao$Place),
    FUN = function(x)
      length(unique(x))
  )
g4 <- g4[order(g4$Group.1), ]
ggplot(g4, aes(
  x = as.factor(Group.1),
  y = x,
  fill = Group.2
)) + ggtitle("Amount of unique students by place of writing") + xlab("Place of writing") + ylab("Student") +
  geom_bar(stat = "identity", position = 'dodge')

# count unique students by School Type
g5 <-
  aggregate(
    datao$Student_ID,
    by = list(datao$Story_ID, datao$School_Type),
    FUN = function(x)
      length(unique(x))
  )
g5 <- g5[order(g5$Group.1), ]
ggplot(g5, aes(
  x = as.factor(Group.1),
  y = x,
  fill = Group.2
)) + ggtitle("Amount of unique students by class type") + xlab("Class Type") + ylab("Student") +
  geom_bar(stat = "identity", position = 'dodge')


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

dataunique <- unique(datao$Feature_Name)
dataun <- data.frame(dataunique)
colnames(dataun)[colnames(dataun) == 'dataunique'] <- 'Feature_Name'
dataun <- annnotate.feature.groups(dataun)
table(dataun$Feature_Group)
