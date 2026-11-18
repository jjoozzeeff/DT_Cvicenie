-- Active: 1795004030219@@127.0.0.1@5432@movielens_elt
-- CREATE DATABASE MOVIELENS_ELT;
\set ON_ERROR_STOP ON
\encoding UTF8

CREATE SCHEMA IF NOT EXISTS bronze;

CREATE TABLE IF NOT EXISTS bronze.ratings(
    id TEXT,
    user_id TEXT,
    movie_id TEXT,
    rating TEXT,
    rated_at TEXT,
    _source_file TEXT DEFAULT 'ratings.csv',
    _loaded_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bronze.users(
    id TEXT,
    age TEXT,
    gender TEXT,
    occupation_id TEXT,
    zip_code TEXT,
    _source_file TEXT DEFAULT 'users.csv',
    _loaded_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bronze.movies(
    id TEXT,
    title TEXT,
    release_year TEXT,
    _source_file TEXT DEFAULT 'movies.csv',
    _loaded_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bronze.occupations(
    id TEXT,
    name TEXT,
    _source_file TEXT DEFAULT 'occupations.csv',
    _loaded_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bronze.age_group(
    id TEXT,
    name TEXT,
    _source_file TEXT DEFAULT 'age_group.csv',
    _loaded_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bronze.genres(
    id TEXT,
    name TEXT,
    _source_file TEXT DEFAULT 'genres.csv',
    _loaded_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bronze.genres_movies(
    id TEXT,
    movie_id TEXT,
    genre_id TEXT,
    _source_file TEXT DEFAULT 'genres_movies.csv',
    _loaded_at TIMESTAMPTZ DEFAULT now()
);

BEGIN;

TRUNCATE bronze.ratings,
bronze.users,
bronze.movies,
bronze.occupations,
bronze.age_group,
bronze.genres,
bronze.genres_movies;

\COPY bronze.occupations (id, name) FROM 'data/occupations.csv' WITH (FORMAT CSV, HEADER TRUE)
\COPY bronze.age_group (id, name) FROM 'data/age_group.csv' WITH (FORMAT CSV, HEADER TRUE)
\COPY bronze.genres (id, name) FROM 'data/genres.csv' WITH (FORMAT CSV, HEADER TRUE)
\COPY bronze.genres_movies (id, movie_id, genre_id) FROM 'data/genres_movies.csv' WITH (FORMAT CSV, HEADER TRUE)
\COPY bronze.users (id, age, gender, occupation_id, zip_code) FROM 'data/users.csv' WITH (FORMAT CSV, HEADER TRUE)
\COPY bronze.movies (id, title, release_year) FROM 'data/movies.csv' WITH (FORMAT CSV, HEADER TRUE)
\COPY bronze.ratings (id, usr_id, movie_id, rating, rated_at) FROM 'data/ratings.csv' WITH (FORMAT CSV, HEADER TRUE)

COMMIT;