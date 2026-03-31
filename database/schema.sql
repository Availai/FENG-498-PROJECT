CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE farmers (
    id SERIAL PRIMARY KEY,
    firebase_uid VARCHAR(128) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE fields (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES farmers(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    area_dekar NUMERIC(10, 2),
    boundary GEOMETRY(Polygon, 4326) NOT NULL, 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE field_analyses (
    id SERIAL PRIMARY KEY,
    field_id INTEGER REFERENCES fields(id) ON DELETE CASCADE,
    crop_name VARCHAR(100) NOT NULL,
    suitability_score NUMERIC(5, 2),
    ai_report TEXT,
    analyzed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);