
# load libraries
library(rvest)
library(dplyr)
library(stringr)
library(purrr)
library(tibble)

# scrape one page
scrape_quotes <- function(page_number) {

  url <- paste0(
    "https://quotes.toscrape.com/page/",
    page_number,
    "/"
  )

  page <- read_html(url)

  quote_nodes <- page %>%
    html_elements(".quote")

  map_dfr(quote_nodes, function(node) {

    quote_text <- node %>%
      html_element(".text") %>%
      html_text2()

    author <- node %>%
      html_element(".author") %>%
      html_text2()

    tags <- node %>%
      html_elements(".tag") %>%
      html_text2() %>%
      paste(collapse = ", ")

    tibble(
      quote = quote_text,
      author = author,
      tags = tags,
      source_page = page_number
    )
  })
}

# extract at least 20 records
raw_quotes <- map_dfr(
  1:3,
  scrape_quotes
)

if (nrow(raw_quotes) < 20) {
  stop("Fewer than 20 records were extracted.")
}

# preserve raw textual content
raw_quotes <- raw_quotes %>%
  mutate(
    quote_length = str_count(
      quote,
      "\\S+"
    )
  )

# inspect raw dataset
print(dim(raw_quotes))
print(head(raw_quotes))
print(colSums(is.na(raw_quotes)))

# save raw data
dir.create(
  "ETL_PostgreSQL/data",
  showWarnings = FALSE
)

write.csv(
  raw_quotes,
  "ETL_PostgreSQL/data/raw_quotes.csv",
  row.names = FALSE
)
