
# project R dependencies
required_packages <- c(
  "rvest",
  "dplyr",
  "tidyr",
  "stringr",
  "tibble",
  "tidytext",
  "tm",
  "igraph",
  "Matrix",
  "ggplot2",
  "wordcloud",
  "topicmodels",
  "slam",
  "reshape2",
  "plyr"
)

# identify missing packages
missing_packages <- setdiff(
  required_packages,
  rownames(installed.packages())
)

# install missing packages
if (length(missing_packages) > 0) {
  install.packages(
    missing_packages,
    lib = Sys.getenv("R_LIBS_USER"),
    repos = "https://cloud.r-project.org"
  )
}

# confirm installation
cat("All required R packages are installed.\n")
