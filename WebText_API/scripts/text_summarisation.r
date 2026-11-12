# load libraries
library(dplyr)
library(tidytext)
library(stringr)
library(igraph)
library(dplyr)
library(tidytext)
library(Matrix)


# prepare sentences
sentences <- web_df %>%
  select(paragraph_id, clean_content) %>%
  unnest_tokens(
    sentence,
    clean_content,
    token = "sentences"
  ) %>%
  mutate(sentence_id = row_number()) %>%
  filter(nchar(sentence) > 30)

# calculate word frequencies
word_scores <- sentences %>%
  unnest_tokens(word, sentence) %>%
  anti_join(stop_words, by = "word") %>%
  filter(str_detect(word, "^[a-z]+$")) %>%
  count(word, name = "frequency")

# calculate sentence scores
sentence_scores <- sentences %>%
  unnest_tokens(word, sentence) %>%
  inner_join(word_scores, by = "word") %>%
  group_by(sentence_id) %>%
  summarise(
    score = sum(frequency) / n(),
    .groups = "drop"
  )

# select top five sentences
frequency_summary <- sentences %>%
  inner_join(
    sentence_scores,
    by = "sentence_id"
  ) %>%
  slice_max(
    score,
    n = 5,
    with_ties = FALSE
  ) %>%
  arrange(sentence_id)

cat(
  paste(frequency_summary$sentence, collapse = " ")
)


library(ggplot2)

word_frequency %>%
  slice_max(
    n,
    n = 15,
    with_ties = FALSE
  ) %>%
  ggplot(
    aes(x = reorder(word, n), y = n)
  ) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Most Frequent Keywords in Web Content",
    x = "Keyword",
    y = "Frequency"
  ) +
  theme_minimal()

ggsave(
  "WebText_API/figures/word_frequency.png",
  width = 10,
  height = 7
)


# create sentence-term matrix
sentence_tokens <- sentences %>%
  unnest_tokens(word, sentence) %>%
  anti_join(stop_words, by = "word") %>%
  filter(str_detect(word, "^[a-z]+$"))

sentence_dtm <- sentence_tokens %>%
  count(sentence_id, word) %>%
  cast_dtm(sentence_id, word, n)

# calculate TF-IDF
term_counts <- as.matrix(sentence_dtm)

term_frequency <- term_counts /
  pmax(rowSums(term_counts), 1)

document_frequency <- colSums(term_counts > 0)

idf <- log(
  (nrow(term_counts) + 1) /
  (document_frequency + 1)
) + 1

tfidf <- sweep(
  term_frequency,
  2,
  idf,
  "*"
)

# cosine similarity
norms <- sqrt(rowSums(tfidf^2))

normalised <- tfidf /
  pmax(norms, 1e-10)

similarity <- normalised %*% t(normalised)

diag(similarity) <- 0

# construct weighted graph
graph <- graph_from_adjacency_matrix(
  similarity,
  mode = "undirected",
  weighted = TRUE,
  diag = FALSE
)

# rank sentences
rank_values <- page_rank(
  graph,
  directed = FALSE,
  weights = E(graph)$weight
)$vector

textrank_scores <- data.frame(
  sentence_id = as.integer(
    rownames(term_counts)
  ),
  score = as.numeric(rank_values)
)

# select top five sentences
textrank_summary <- sentences %>%
  inner_join(
    textrank_scores,
    by = "sentence_id"
  ) %>%
  slice_max(
    score,
    n = 5,
    with_ties = FALSE
  ) %>%
  arrange(sentence_id)

cat(
  paste(textrank_summary$sentence, collapse = " ")
)

comparison <- sentence_scores %>%
  rename(
    Frequency = score
  ) %>%
  full_join(
    textrank_scores %>%
      rename(TextRank = score),
    by = "sentence_id"
  ) %>%
  mutate(
    Frequency = Frequency / max(Frequency, na.rm = TRUE),
    TextRank = TextRank / max(TextRank, na.rm = TRUE)
  ) %>%
  pivot_longer(
    cols = c(Frequency, TextRank),
    names_to = "method",
    values_to = "score"
  )

ggplot(
  comparison,
  aes(
    x = sentence_id,
    y = score,
    colour = method
  )
) +
  geom_line() +
  labs(
    title = "Comparison of Sentence Importance Scores",
    x = "Sentence Number",
    y = "Normalised Importance Score",
    colour = "Method"
  ) +
  theme_minimal()

ggsave(
  "WebText_API/figures/summary_comparison.png",
  width = 11,
  height = 6
)
