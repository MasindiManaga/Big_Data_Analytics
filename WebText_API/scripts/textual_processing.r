# load libraries
library(dplyr)
library(stringr)
library(tidytext)

# load processed dataset
web_data <- read.csv(
  "D:/BigDataAnalytics/WebText_API/data/processed/web_content_clean.csv",
  stringsAsFactors = FALSE
)

# inspect dataset
print(dim(web_data))
print(names(web_data))
print(head(web_data$content, 3))

# convert text to lowercase
web_data <- web_data |>
  mutate(clean_text = str_to_lower(content))

# tokenize text into words
tokens <- web_data |>
  select(paragraph_id, clean_text) |>
  unnest_tokens(word, clean_text)

# remove stop words and numeric tokens
filtered_tokens <- tokens |>
  anti_join(stop_words, by = "word") |>
  filter(!str_detect(word, "^[0-9]+$"))

# calculate word frequencies
word_freq <- filtered_tokens |>
  count(word, sort = TRUE)

# inspect top words
print(head(word_freq, 15))

# inspect results
print(dim(tokens))
print(dim(filtered_tokens))
print(head(word_freq, 15))

# load visualisation library
library(ggplot2)

# select top 15 words
top_words <- word_freq |>
  slice_head(n = 15)

# create word frequency chart
word_plot <- ggplot(
  top_words,
  aes(x = reorder(word, n), y = n)
) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Most Frequent Words in R Documentation",
    x = "Words",
    y = "Frequency"
  ) +
  theme_minimal()

# display chart
print(word_plot)

# create figures folder
figures_dir <- "D:/BigDataAnalytics/WebText_API/figures"

dir.create(
  figures_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

# save chart
ggsave(
  filename = file.path(figures_dir, "word_frequency.png"),
  plot = word_plot,
  width = 10,
  height = 6,
  dpi = 300
)

# verify saved chart
file.exists(file.path(figures_dir, "word_frequency.png"))

# load library
library(wordcloud)

# save word cloud
png(
  "D:/BigDataAnalytics/WebText_API/figures/word_cloud.png",
  width = 1200,
  height = 800,
  res = 150
)

# generate word cloud
wordcloud(
  words = word_freq$word,
  freq = word_freq$n,
  min.freq = 2,
  max.words = 100,
  random.order = FALSE,
  colors = c("steelblue", "darkblue", "grey40")
)

# close graphics device
dev.off()

# verify saved file
file.exists(
  "D:/BigDataAnalytics/WebText_API/figures/word_cloud.png"
)