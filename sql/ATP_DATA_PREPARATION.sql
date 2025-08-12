create database tennis_db;

CREATE SCHEMA tennis_db.atp;
USE DATABASE tennis_db;
USE SCHEMA atp;

CREATE OR REPLACE STAGE tennis_stage;

CREATE OR REPLACE FILE FORMAT csv_format
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    NULL_IF = ('NULL', '')
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';


CREATE OR REPLACE TABLE players (
    player_id INTEGER PRIMARY KEY,
    first_name STRING,
    last_name STRING,
    hand STRING,
    birth_date STRING,
    country_code STRING,
    height INTEGER,
    wikidata_id STRING
);

CREATE OR REPLACE TABLE matches (
    tourney_id STRING,
    tourney_name STRING,
    surface STRING,
    draw_size INTEGER,
    tourney_level STRING,
    tourney_date STRING,
    match_num INTEGER,
    winner_id INTEGER,
    winner_seed STRING,
    winner_entry STRING,
    winner_name STRING,
    winner_hand STRING,
    winner_ht INTEGER,
    winner_ioc STRING,
    winner_age FLOAT,
    loser_id INTEGER,
    loser_seed STRING,
    loser_entry STRING,
    loser_name STRING,
    loser_hand STRING,
    loser_ht INTEGER,
    loser_ioc STRING,
    loser_age FLOAT,
    score STRING,
    best_of INTEGER,
    round STRING,
    minutes INTEGER,
    w_ace INTEGER,
    w_df INTEGER,
    w_svpt INTEGER,
    w_1stin INTEGER,
    w_1stWon INTEGER,
    w_2ndWon INTEGER,
    w_SvGms INTEGER,
    w_bpSaved INTEGER,
    w_bpFaced INTEGER,
    l_ace INTEGER,
    l_df INTEGER,
    l_svpt INTEGER,
    l_1stin INTEGER,
    l_1stWon INTEGER,
    l_2ndWon INTEGER,
    l_SvGms INTEGER,
    l_bpSaved INTEGER,
    l_bpFaced INTEGER,
    winner_rank INTEGER,
    winner_rank_points INTEGER,
    loser_rank INTEGER,
    loser_rank_points INTEGER,
    CONSTRAINT fk_winner FOREIGN KEY (winner_id) REFERENCES players(player_id),
    CONSTRAINT fk_loser FOREIGN KEY (loser_id) REFERENCES players(player_id)
);

COPY INTO players
FROM @tennis_stage/atp_players.csv
FILE_FORMAT = (FORMAT_NAME = csv_format);

COPY INTO matches
FROM @tennis_stage
FILE_FORMAT = (FORMAT_NAME = csv_format)
PATTERN = 'atp_matches_20[0-1][0-9]\.csv';

List @tennis_stage;


SELECT COUNT(*) AS total_rows FROM matches;
SELECT * FROM matches LIMIT 5;
SELECT COUNT(*) AS player_rows FROM players;
SELECT * FROM players LIMIT 5;

UPDATE matches
SET 
    w_ace = COALESCE(w_ace, 0),
    l_ace = COALESCE(l_ace, 0),
    w_svpt = COALESCE(w_svpt, 0),
    l_svpt = COALESCE(l_svpt, 0),
    w_1stin = COALESCE(w_1stin, 0),
    l_1stin = COALESCE(l_1stin, 0),
    w_1stWon = COALESCE(w_1stWon, 0),
    l_1stWon = COALESCE(l_1stWon, 0),
    w_2ndWon = COALESCE(w_2ndWon, 0),
    l_2ndWon = COALESCE(l_2ndWon, 0),
    minutes = COALESCE(minutes, 0);

Update matches
set WINNER_SEED = coalesce(WINNER_SEED , 'UNSEEDED'),
    LOSER_SEED = coalesce(LOSER_SEED, 'UNSEEDED');
  

ALTER TABLE matches
ADD tourney_date_converted DATE;

UPDATE matches
SET tourney_date_converted = TO_DATE(tourney_date, 'YYYYMMDD');

ALTER TABLE matches
DROP COLUMN tourney_date;

ALTER TABLE matches
RENAME COLUMN tourney_date_converted TO tourney_date;

select * from matches;

CREATE OR REPLACE FILE FORMAT tennis_stage_csv
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  EMPTY_FIELD_AS_NULL = TRUE
  COMPRESSION = 'NONE';





