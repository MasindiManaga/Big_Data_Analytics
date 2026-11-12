
# load libraries
library(dplyr)
library(tidytext)
library(stringr)
library(tidyr)
library(igraph)
library(Matrix)
library(ggplot2)

# load processed data
web_df <- read.csv(
  "D:/BigDataAnalytics/WebText_API/data/processed/web_content_clean.csv",
  stringsAsFactors = FALSE
)

# prepare sentences
sentences <- web_df %>%
  select(paragraph_id, content) %>%
  unnest_tokens(sentence, content, token = "sentences") %>%
  mutate(sentence_id = row_number()) %>%
  filter(nchar(sentence) > 30)

# calculate word frequencies
word_scores <- sentences %>%
  unnest_tokens(word, sentence) %>%
  anti_join(stop_words, by = "word") %>%
  filter(str_detect(word, "^[a-z]+$")) %>%
  count(word, name = "frequency")

# calculate frequency-based sentence scores
sentence_scores <- sentences %>%
  unnest_tokens(word, sentence) %>%
  inner_join(word_scores, by = "word") %>%
  group_by(sentence_id) %>%
  summarise(
    score = sum(frequency) / sqrt(n()),
    word_count = n(),
    .groups = "drop"
  )

# generate frequency-based summary
frequency_summary <- sentences %>%
  inner_join(sentence_scores, by = "sentence_id") %>%
  filter(word_count >= 8, word_count <= 60) %>%
  slice_max(score, n = 5, with_ties = FALSE) %>%
  arrange(sentence_id)

cat("\nFREQUENCY-BASED SUMMARY\n")
cat(paste(frequency_summary$sentence, collapse = "\n\n"))

# prepare sentence tokens
sentence_tokens <- sentences %>%
  unnest_tokens(word, sentence) %>%
  anti_join(stop_words, by = "word") %>%
  filter(str_detect(word, "^[a-z]+$"))

# create sentence-term matrix
sentence_dtm <- sentence_tokens %>%
  count(sentence_id, word) %>%
  cast_dtm(sentence_id, word, n)

# convert to sparse matrix
term_counts <- as(sentence_dtm, "sparseMatrix")

# calculate TF-IDF
term_frequency <- term_counts /
  pmax(Matrix::rowSums(term_counts), 1)

document_frequency <- Matrix::colSums(term_counts > 0)

idf <- log(
  (nrow(term_counts) + 1) /
  (document_frequency + 1)
) + 1

tfidf <- term_frequency %*%
  Matrix::Diagonal(x = as.numeric(idf))

# calculate cosine similarity
norms <- sqrt(Matrix::rowSums(tfidf^2))

normalised <- Matrix::Diagonal(
  x = 1 / pmax(norms, 1e-10)
) %*% tfidf

similarity <- Matrix::tcrossprod(normalised)
diag(similarity) <- 0

# create sentence similarity graph
graph <- igraph::graph_from_adjacency_matrix(
  similarity,
  mode = "undirected",
  weighted = TRUE,
  diag = FALSE
)

# calculate TextRank scores
rank_values <- igraph::page_rank(
  graph,
  directed = FALSE,
  weights = igraph::E(graph)$weight
)$vector

textrank_scores <- data.frame(
  sentence_id = as.integer(rownames(term_counts)),
  score = as.numeric(rank_values)
)

# generate TextRank summary
textrank_summary <- sentences %>%
  inner_join(textrank_scores, by = "sentence_id") %>%
  slice_max(score, n = 5, with_ties = FALSE) %>%
  arrange(sentence_id)

cat("\n\nTEXTRANK SUMMARY\n")
cat(paste(textrank_summary$sentence, collapse = "\n\n"))

# compare summarisation scores
comparison <- sentence_scores %>%
  select(sentence_id, Frequency = score) %>%
  full_join(
    textrank_scores %>%
      select(sentence_id, TextRank = score),
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

# create comparison chart
comparison_plot <- ggplot(
  comparison,
  aes(x = sentence_id, y = score, colour = method)
) +
  geom_line() +
  labs(
    title = "Comparison of Sentence Importance Scores",
    x = "Sentence Number",
    y = "Normalised Importance Score",
    colour = "Method"
  ) +
  theme_minimal()

# save comparison chart
ggsave(
  "D:/BigDataAnalytics/WebText_API/figures/summary_comparison.png",
  plot = comparison_plot,
  width = 11,
  height = 6,
  dpi = 300
)

# verify output
print(file.exists(
  "D:/BigDataAnalytics/WebText_API/figures/summary_comparison.png"
))

# prepare top sentence scores
top_scores <- bind_rows(
  frequency_summary %>%
    transmute(
      sentence_id,
      method = "Frequency-based",
      score = score / max(sentence_scores$score)
    ),
  textrank_summary %>%
    transmute(
      sentence_id,
      method = "TextRank",
      score = score / max(textrank_scores$score)
    )
)

# visualise top-ranked sentences
top_sentences_plot <- ggplot(
  top_scores,
  aes(
    x = reorder(as.factor(sentence_id), score),
    y = score,
    fill = method
  )
) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  facet_wrap(~ method, scales = "free_y") +
  labs(
    title = "Top Five Sentences by Summarisation Method",
    subtitle = "Sentence scores normalised within each method",
    x = "Sentence ID",
    y = "Normalised Importance Score"
  ) +
  theme_minimal()

# save visualisation
ggsave(
  "D:/BigDataAnalytics/WebText_API/figures/top_summary_sentences.png",
  plot = top_sentences_plot,
  width = 11,
  height = 6,
  dpi = 300
)

# verify output
file.exists(
  "D:/BigDataAnalytics/WebText_API/figures/top_summary_sentences.png"
)