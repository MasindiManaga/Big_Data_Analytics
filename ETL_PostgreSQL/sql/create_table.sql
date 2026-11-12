CREATE TABLE IF NOT EXISTS quotes (
    quote_id SERIAL PRIMARY KEY,
    quote TEXT NOT NULL,
    author VARCHAR(255) NOT NULL,
    tags TEXT,
    source_page INTEGER,
    quote_length INTEGER NOT NULL
        CHECK (quote_length >= 0)
);