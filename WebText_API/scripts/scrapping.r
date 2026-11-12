# load libraries
library(rvest)
library(dplyr)
library(stringr)
library(tibble)
library(ggplot2)

# define web text extraction
extract_web_text <- function(url) {

  page <- read_html(url)

  title <- page |>
    html_element("title") |>
    html_text2() |>
    str_squish()

  paragraphs <- page |>
    html_elements("p") |>
    html_text2()

  # remove empty and short paragraphs
  paragraphs <- str_squish(paragraphs)

  paragraphs <- paragraphs[
    !is.na(paragraphs) &
      str_length(paragraphs) >= 80
  ]

  tibble(
    url = url,
    title = title,
    paragraph_id = seq_along(paragraphs),
    content = paragraphs
  )
}

# specify source
website_url <- "https://cran.r-project.org/doc/manuals/r-release/R-intro.html"

# extract content
web_df <- extract_web_text(website_url)

# inspect extracted data
print(dim(web_df))
print(head(web_df, 10))

# define output folders
raw_dir <- "D:/BigDataAnalytics/WebText_API/data/raw"
processed_dir <- "D:/BigDataAnalytics/WebText_API/data/processed"

dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

# save raw dataset
write.csv(
  web_df,
  file.path(raw_dir, "web_content.csv"),
  row.names = FALSE
)

# clean extracted content
clean_web_df <- web_df |>
  mutate(content = str_squish(content)) |>
  filter(
    !grepl("^Next:|^Previous:|^Up:", content),
    !grepl("^Copyright|^Permission is granted", content),
    !grepl("^Comments and corrections", content)
  ) |>
  distinct(content, .keep_all = TRUE)

# save processed dataset
write.csv(
  clean_web_df,
  file.path(processed_dir, "web_content_clean.csv"),
  row.names = FALSE
)

# verify saved datasets
print(file.exists(
  file.path(raw_dir, "web_content.csv")
))

print(file.exists(
  file.path(processed_dir, "web_content_clean.csv")
))