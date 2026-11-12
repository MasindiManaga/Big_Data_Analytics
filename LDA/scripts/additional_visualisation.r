# load libraries
library(ggplot2)
library(tidytext)
library(dplyr)

top_words %>%
  mutate(
    term_label = reorder_within(
      term, beta, topic
    )
  ) %>%
  ggplot(
    aes(x = beta, y = term_label, fill = factor(topic))
  ) +
  geom_col(show.legend = FALSE) +
  facet_wrap(
    ~ topic,
    scales = "free_y"
  ) +
  scale_y_reordered() +
  labs(
    title = "Top 10 Keywords per LDA Topic",
    x = "Word Probability",
    y = "Keyword"
  ) +
  theme_minimal()

ggsave(
  "LDA/figures/topic_keywords.png",
  width = 12,
  height = 8
)


ggplot(
  document_topics,
  aes(
    x = factor(topic),
    y = document,
    fill = gamma
  )
) +
  geom_tile(color = "white") +
  scale_fill_gradient(
    low = "#fde7c0",
    high = "#df0025"
  ) +
  labs(
    title = "LDA Topic Distribution Across News Documents",
    x = "Topic",
    y = "Document",
    fill = "Probability"
  ) +
  theme_minimal()

ggsave(
  "LDA/figures/heatmap.png",
  width = 10,
  height = 7
)

# keyword probability heatmap
keyword_heatmap <- top_words %>%
  ggplot(
    aes(
      x = factor(topic),
      y = term,
      fill = beta
    )
  ) +
  geom_tile(color = "white") +
  scale_fill_gradient(
    low = "#f1f5f9",
    high = "#2563eb"
  ) +
  labs(
    title = "Top Keyword Probabilities Across LDA Topics",
    x = "LDA Topic",
    y = "Keyword",
    fill = "Beta"
  ) +
  theme_minimal()

ggsave(
  "LDA/figures/keyword_heatmap.png",
  plot = keyword_heatmap,
  width = 10,
  height = 9
)