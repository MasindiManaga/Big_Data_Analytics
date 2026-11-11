# load libraries
library(dplyr)
library(stringr)
library(tm)
library(tidytext)

# load documents
files <- list.files(
  "D:/BigDataAnalytics/LDA/data/raw/news/sa_news",
  pattern = "^news_[0-9]+\\.txt$",
  full.names = TRUE
)

stopifnot(length(files) > 0)

news_df <- data.frame(
  file_name = basename(files),
  content = vapply(
    files,
    function(file) {
      paste(readLines(
        file,
        warn = FALSE,
        encoding = "UTF-8"
      ), collapse = " ")
    },
    character(1)
  ),
  row.names = NULL
)

# inspect data
print(dim(news_df))
print(head(news_df))
print(colSums(is.na(news_df)))

# preprocess
news_df <- news_df %>%
  mutate(
    clean_content = str_to_lower(content),
    clean_content = str_replace_all(
      clean_content,
      "https?://\\S+|www\\.\\S+",
      " "
    ),
    clean_content = str_replace_all(
      clean_content,
      "[^[:alpha:]\\s]",
      " "
    ),
    clean_content = str_squish(clean_content)
  )

# remove stopwords and short terms
data("stop_words", package = "tidytext")

tokens <- news_df %>%
  select(file_name, clean_content) %>%
  unnest_tokens(word, clean_content) %>%
  anti_join(stop_words, by = "word") %>%
  filter(nchar(word) > 2)

# examine vocabulary
print(tokens %>% count(word, sort = TRUE))


# save Q2.1 results
results_dir <- "D:/BigDataAnalytics/LDA/results"
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

write.csv(
  news_df[, c("file_name", "content")],
  file.path(results_dir, "news_dataframe.csv"),
  row.names = FALSE
)

write.csv(
  news_df,
  file.path(results_dir, "cleaned_dataframe.csv"),
  row.names = FALSE
)

word_frequencies <- tokens %>%
  count(word, sort = TRUE)

write.csv(
  word_frequencies,
  file.path(results_dir, "word_frequencies.csv"),
  row.names = FALSE
)

cat("Question 2.1 results saved to:", results_dir, "\n")
