write.csv(
  author_results,
  "ETL_PostgreSQL/results/author_analysis.csv",
  row.names = FALSE
)

write.csv(
  tag_results,
  "ETL_PostgreSQL/results/tag_analysis.csv",
  row.names = FALSE
)

file.exists("ETL_PostgreSQL/results/author_analysis.csv")
file.exists("ETL_PostgreSQL/results/tag_analysis.csv")