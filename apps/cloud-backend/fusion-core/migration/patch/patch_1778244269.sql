CREATE TYPE output_type AS ENUM ('media', 'amplifier');

CREATE TABLE output (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type output_type NOT NULL,
    images TEXT NOT NULL,
    specifications JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
);