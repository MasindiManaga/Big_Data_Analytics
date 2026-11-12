
# load libraries
library(DBI)
library(RPostgres)
library(ggplot2)
library(dplyr)

# database connection settings
db_name <- "quotes_etl_db"
db_host <- "localhost"
db_port <- 5432
db_user <- "postgres"

# connect to PostgreSQL
connection <- dbConnect(
  RPostgres::Postgres(),
  dbname = db_name,
  host = db_host,
  port = db_port,
  user = db_user
)

# verify imported records
record_count <- dbGetQuery(
  connection,
  "SELECT COUNT(*) AS total_records FROM quotes"
)

print(record_count)

# investigation 1: author analysis
author_query <- "
SELECT
    author,
    COUNT(*) AS total_quotes,
    ROUND(AVG(quote_length)::numeric, 2) AS average_word_count
FROM quotes
GROUP BY author
ORDER BY total_quotes DESC, author
LIMIT 10;
"

author_results <- dbGetQuery(connection, author_query)

# convert database integer values for visualisation
author_results <- author_results %>%
  mutate(total_quotes = as.numeric(total_quotes))

print(author_results)

# investigation 2: tag analysis
tag_query <- "
SELECT
    TRIM(tag) AS category,
    COUNT(*) AS total_occurrences,
    ROUND(AVG(q.quote_length)::numeric, 2) AS average_word_count
FROM quotes AS q
CROSS JOIN LATERAL
    unnest(string_to_array(q.tags, ',')) AS tag
GROUP BY TRIM(tag)
ORDER BY total_occurrences DESC, category
LIMIT 10;
"

tag_results <- dbGetQuery(connection, tag_query)

print(tag_results)

# export analytical results
dir.create(
  "ETL_PostgreSQL/results",
  recursive = TRUE,
  showWarnings = FALSE
)

write.csv(
  author_results,
  "ETL_PostgreSQL/results/author_analysis.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

write.csv(
  tag_results,
  "ETL_PostgreSQL/results/tag_analysis.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

# close database connection
dbDisconnect(connection)


# create author visualisation
author_plot <- ggplot(
  author_results,
  aes(
    x = reorder(author, total_quotes),
    y = total_quotes
  )
) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Top Authors by Number of Quotations",
    x = "Author",
    y = "Number of Quotations"
  ) +
  theme_minimal()

# create figures folder
dir.create(
  "ETL_PostgreSQL/figures",
  recursive = TRUE,
  showWarnings = FALSE
)

# save author visualisation
ggsave(
  filename = "ETL_PostgreSQL/figures/top_authors.png",
  plot = author_plot,
  width = 10,
  height = 7,
  dpi = 300
)

# verify visualisation
print(file.exists(
  "ETL_PostgreSQL/figures/top_authors.png"
))
