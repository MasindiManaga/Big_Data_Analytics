
library(dplyr)
library(stringr)
library(tidyr)

# clean and transform data
clean_quotes <- raw_quotes %>%
  mutate(
    quote = str_squish(quote),
    quote = str_remove_all(
      quote,
      "^[“”\"']+|[“”\"']+$"
    ),
    author = str_squish(author),
    tags = str_squish(tags),
    author = na_if(author, ""),
    tags = na_if(tags, "")
  ) %>%
  filter(
    !is.na(quote),
    quote != ""
  ) %>%
  distinct(
    quote,
    author,
    .keep_all = TRUE
  ) %>%
  mutate(
    author = replace_na(
      author,
      "Unknown"
    ),
    tags = replace_na(
      tags,
      "Uncategorised"
    ),
    quote_length = str_count(
      quote,
      "\\S+"
    ),
    quote_length = as.integer(
      quote_length
    )
  )

# validate cleaned dataset
stopifnot(
  nrow(clean_quotes) >= 20,
  !anyNA(clean_quotes$quote),
  !anyNA(clean_quotes$author),
  !anyNA(clean_quotes$quote_length)
)

# inspect results
print(summary(clean_quotes))
print(colSums(is.na(clean_quotes)))
print(sum(duplicated(clean_quotes)))

# export CSV
write.csv(
  clean_quotes,
  "ETL_PostgreSQL/data/clean_quotes.csv",
  row.names = FALSE
)


quality_report <- data.frame(
  metric = c(
    "Number of records",
    "Missing authors",
    "Missing tags",
    "Duplicate quote-author pairs"
  ),
  before = c(
    nrow(raw_quotes),
    sum(is.na(raw_quotes$author) |
          trimws(raw_quotes$author) == ""),
    sum(is.na(raw_quotes$tags) |
          trimws(raw_quotes$tags) == ""),
    sum(duplicated(
      raw_quotes[c("quote", "author")]
    ))
  ),
  after = c(
    nrow(clean_quotes),
    sum(is.na(clean_quotes$author)),
    sum(is.na(clean_quotes$tags)),
    sum(duplicated(
      clean_quotes[c("quote", "author")]
    ))
  )
)

print(quality_report)

write.csv(
  quality_report,
  "ETL_PostgreSQL/results/data_quality_report.csv",
  row.names = FALSE
)
