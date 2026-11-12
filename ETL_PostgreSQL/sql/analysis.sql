
-- Question 4.3: SQL analytical investigations
-- Database: quotes_etl_db
-- Table: quotes

-- Investigation 1: Author frequency and average quotation length
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


-- Investigation 2:Tag frequency and average quotation length
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
