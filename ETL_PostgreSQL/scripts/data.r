
library(dplyr)
library(stringr)
library(tidyr)

# load raw dataset
raw_quotes <- read.csv(
  "ETL_PostgreSQL/data/raw_quotes.csv",
  stringsAsFactors = FALSE,
  fileEncoding = "UTF-8"
)

# standardise text
standardised_quotes <- raw_quotes %>%
  mutate(
    quote = str_squish(quote),
    quote = str_remove_all(quote, "^[“”\"']+|[“”\"']+$"),
    quote = str_squish(quote),
    author = str_squish(author),
    tags = str_squish(tags),
    author = na_if(author, ""),
    tags = na_if(tags, ""),
    author = if_else(
      str_to_lower(author) %in% c("na", "n/a", "null"),
      NA_character_,
      author
    ),
    tags = if_else(
      str_to_lower(tags) %in% c("na", "n/a", "null"),
      NA_character_,
      tags
    )
  )

# clean and transform data
clean_quotes <- standardised_quotes %>%
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
    author = replace_na(author, "Unknown"),
    tags = replace_na(tags, "Uncategorised"),
    quote_length = as.integer(
      str_count(quote, "\\S+")
    )
  )

# validate cleaned dataset
stopifnot(
  nrow(clean_quotes) >= 20,
  !anyNA(clean_quotes$quote),
  !anyNA(clean_quotes$author),
  !anyNA(clean_quotes$tags),
  !anyNA(clean_quotes$quote_length),
  !anyDuplicated(clean_quotes[c("quote", "author")])
)

# inspect results
print(summary(clean_quotes))
print(colSums(is.na(clean_quotes)))
print(sum(duplicated(clean_quotes)))

# export cleaned dataset
write.csv(
  clean_quotes,
  "ETL_PostgreSQL/data/clean_quotes.csv",
  row.names = FALSE
)

# generate data quality report
quality_report <- data.frame(
  metric = c(
    "Number of records",
    "Missing authors",
    "Missing tags",
    "Duplicate quote-author pairs"
  ),
  before = c(
    nrow(raw_quotes),
    sum(is.na(standardised_quotes$author)),
    sum(is.na(standardised_quotes$tags)),
    sum(duplicated(
      standardised_quotes[c("quote", "author")]
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

# export quality report
write.csv(
  quality_report,
  "ETL_PostgreSQL/results/data_quality_report.csv",
  row.names = FALSE
)