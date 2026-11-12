
CREATE TABLE IF NOT EXISTS quotes (
    quote_id SERIAL PRIMARY KEY,
    quote TEXT NOT NULL,
    author VARCHAR(255) NOT NULL,
    tags TEXT,
    source_page INTEGER,
    quote_length INTEGER NOT NULL
        CHECK (quote_length >= 0)
);


# load database libraries
library(DBI)
library(RPostgres)

# connect to PostgreSQL
con <- dbConnect(
  RPostgres::Postgres(),
  dbname = Sys.getenv("PGDATABASE"),
  host = Sys.getenv("PGHOST", "localhost"),
  port = as.integer(
    Sys.getenv("PGPORT", "5432")
  ),
  user = Sys.getenv("PGUSER"),
  password = Sys.getenv("PGPASSWORD")
)

# read cleaned CSV
clean_quotes <- read.csv(
  "ETL_PostgreSQL/data/clean_quotes.csv",
  stringsAsFactors = FALSE
)

# import records
dbWithTransaction(con, {

  dbExecute(con, "TRUNCATE TABLE quotes RESTART IDENTITY")

  dbWriteTable(
    con,
    "quotes",
    clean_quotes,
    append = TRUE,
    row.names = FALSE
  )
})

# verify record count
print(
  dbGetQuery(
    con,
    "SELECT COUNT(*) AS total_records FROM quotes"
  )
)

dbDisconnect(con)


SELECT
    author,
    COUNT(*) AS total_quotes,
    ROUND(
        AVG(quote_length)::numeric,
        2
    ) AS average_word_count
FROM quotes
GROUP BY author
ORDER BY total_quotes DESC, author
LIMIT 10;

SELECT
    TRIM(tag) AS category,
    COUNT(*) AS total_occurrences,
    ROUND(
        AVG(q.quote_length)::numeric,
        2
    ) AS average_word_count
FROM quotes AS q
CROSS JOIN LATERAL
    unnest(
        string_to_array(q.tags, ',')
    ) AS tag
GROUP BY TRIM(tag)
ORDER BY total_occurrences DESC, category
LIMIT 10;


library(DBI)
library(RPostgres)
library(ggplot2)

con <- dbConnect(
  RPostgres::Postgres(),
  dbname = Sys.getenv("PGDATABASE"),
  host = Sys.getenv("PGHOST", "localhost"),
  user = Sys.getenv("PGUSER"),
  password = Sys.getenv("PGPASSWORD")
)

author_results <- dbGetQuery(
  con,
  "
  SELECT author, COUNT(*) AS total_quotes
  FROM quotes
  GROUP BY author
  ORDER BY total_quotes DESC, author
  LIMIT 10
  "
)

ggplot(
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

ggsave(
  "ETL_PostgreSQL/figures/top_authors.png",
  width = 10,
  height = 7
)

dbDisconnect(con)
