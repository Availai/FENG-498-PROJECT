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

CREATE TABLE plants (
    id SERIAL PRIMARY KEY,
    scientific_name VARCHAR(150) UNIQUE NOT NULL,
    common_name VARCHAR(150),
    family VARCHAR(100),
    cycle VARCHAR(50),
    watering VARCHAR(50),
    sunlight VARCHAR(100),
    hardiness_min INTEGER,
    hardiness_max INTEGER,
    ideal_ph_min NUMERIC(3, 1),
    ideal_ph_max NUMERIC(3, 1),
    ideal_temp_min NUMERIC(4, 1),
    ideal_temp_max NUMERIC(4, 1),
    care_level VARCHAR(50),
    disease_risks TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE field_plants (
    id SERIAL PRIMARY KEY,
    field_id INTEGER REFERENCES fields(id) ON DELETE CASCADE,
    plant_id INTEGER REFERENCES plants(id) ON DELETE RESTRICT,
    planted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'active'
);