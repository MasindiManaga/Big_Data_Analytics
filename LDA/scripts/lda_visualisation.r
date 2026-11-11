# load libraries
library(topicmodels)
library(tidytext)
library(dplyr)
library(tidyr)

set.seed(123)

# load documents
files <- list.files(
  "D:/BigDataAnalytics/LDA/data/raw/news/sa_news",
  pattern = "^news_[0-9]+\\.txt$",
  full.names = TRUE
)

# load preprocessed tokens
source("D:/BigDataAnalytics/LDA/scripts/dataframe_creation.r")

# count words in each document
word_counts <- tokens %>%
  count(file_name, word, name = "n")

# create document-term matrix
dtm <- word_counts %>%
  cast_dtm(file_name, word, n)

# remove empty documents
dtm <- dtm[slam::row_sums(dtm) > 0, ]



# fit LDA
lda_model <- LDA(
  dtm,
  k = 4,
  method = "Gibbs",
  control = list(
    seed = 123,
    burnin = 500,
    iter = 2000,
    thin = 100
  )
)

# extract word-topic probabilities
topic_terms <- tidy(
  lda_model,
  matrix = "beta"
)

# extract document-topic probabilities
document_topics <- tidy(
  lda_model,
  matrix = "gamma"
)

# top 10 words per topic
top_words <- topic_terms %>%
  group_by(topic) %>%
  slice_max(
    beta,
    n = 10,
    with_ties = FALSE
  ) %>%
  arrange(topic, desc(beta)) %>%
  ungroup()

print(top_words)

# dominant topic per document
dominant_topics <- document_topics %>%
  group_by(document) %>%
  slice_max(
    gamma,
    n = 1,
    with_ties = FALSE
  ) %>%
  ungroup()

print(dominant_topics)

# save results
dir.create("LDA/results", showWarnings = FALSE)

write.csv(
  top_words,
  "LDA/results/top_topic_words.csv",
  row.names = FALSE
)

write.csv(
  document_topics,
  "LDA/results/document_topic_distribution.csv",
  row.names = FALSE
)