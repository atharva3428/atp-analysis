CREATE OR REPLACE TABLE player_stats AS
SELECT 
    player_id,
    player_name,
    SUM(CASE WHEN is_winner THEN 1 ELSE 0 END) AS total_wins,
    COUNT(DISTINCT CASE WHEN is_winner AND ROUND = 'F' THEN tourney_name END) AS tournaments_won,
    SUM(CASE WHEN is_winner AND tourney_level = 'G' AND ROUND = 'F' THEN 1 ELSE 0 END) AS grand_slam_wins,
    AVG(CASE WHEN is_winner THEN W_1STWON::FLOAT / NULLIF(W_1STIN, 0) ELSE L_1STWON::FLOAT / NULLIF(L_1STIN, 0) END) AS avg_first_serve_win_pct,
    AVG(CASE WHEN is_winner THEN W_ACE::FLOAT / NULLIF(W_SVPT, 0) ELSE L_ACE::FLOAT / NULLIF(L_SVPT, 0) END) AS avg_ace_pct
FROM (
    SELECT 
        WINNER_ID AS player_id, 
        WINNER_NAME AS player_name, 
        TRUE AS is_winner, 
        tourney_name, 
        tourney_level, 
        ROUND, 
        W_1STWON, 
        W_1STIN, 
        W_ACE, 
        W_SVPT,
        L_1STWON, 
        L_1STIN, 
        L_ACE, 
        L_SVPT
    FROM matches
    UNION ALL
    SELECT 
        LOSER_ID, 
        LOSER_NAME, 
        FALSE, 
        tourney_name, 
        tourney_level, 
        ROUND, 
        W_1STWON, 
        W_1STIN, 
        W_ACE, 
        W_SVPT,
        L_1STWON, 
        L_1STIN, 
        L_ACE, 
        L_SVPT
    FROM matches
) AS combined
GROUP BY player_id, player_name
order by grand_slam_wins desc;




CREATE OR REPLACE TABLE tournament_stats AS
WITH final_wins AS (
    SELECT 
        tourney_name,
        tourney_level,
        surface,
        WINNER_NAME AS top_winner,
        COUNT(*) AS win_count,
        ROW_NUMBER() OVER (
            PARTITION BY tourney_name, tourney_level, surface 
            ORDER BY COUNT(*) DESC, WINNER_NAME ASC
        ) AS rn
    FROM matches
    WHERE ROUND = 'F' AND tourney_level != 'D'
    GROUP BY tourney_name, tourney_level, surface, WINNER_NAME
)
SELECT 
    m.tourney_name,
    m.tourney_level,
    m.surface,
    COUNT(*) AS total_matches,
    AVG(m.minutes) AS avg_match_duration,
    f.top_winner AS most_successful_player,
    f.win_count AS top_winner_count
FROM matches m
LEFT JOIN final_wins f
    ON m.tourney_name = f.tourney_name 
    AND m.tourney_level = f.tourney_level 
    AND m.surface = f.surface
    AND f.rn = 1
WHERE m.tourney_level != 'D'
GROUP BY m.tourney_name, m.tourney_level, m.surface, f.top_winner, f.win_count;

-- Base CTE for Player Matches
-- This unions winner and loser data for per-player aggregations.

CREATE OR REPLACE VIEW player_matches_view AS
SELECT 
    YEAR(m.tourney_date) AS year,
    m.tourney_level,
    m.draw_size,
    m.winner_id AS player_id,
    m.winner_name AS player_name,
    m.winner_hand AS hand,
    m.winner_ioc AS country,
    m.winner_ht AS height,
    m.winner_age AS age,
    m.winner_rank AS rank,
    1 AS is_win,
    m.w_ace AS aces,
    m.w_df AS double_faults,
    m.w_1stin / NULLIF(m.w_svpt, 0) AS first_serve_pct,
    m.w_bpSaved / NULLIF(m.w_bpFaced, 0) AS bp_save_pct
FROM matches m
UNION ALL
SELECT 
    YEAR(m.tourney_date) AS year,
    m.tourney_level,
    m.draw_size,
    m.loser_id AS player_id,
    m.loser_name AS player_name,
    m.loser_hand AS hand,
    m.loser_ioc AS country,
    m.loser_ht AS height,
    m.loser_age AS age,
    m.loser_rank AS rank,
    0 AS is_win,
    m.l_ace AS aces,
    m.l_df AS double_faults,
    m.l_1stin / NULLIF(m.l_svpt, 0) AS first_serve_pct,
    m.l_bpSaved / NULLIF(m.l_bpFaced, 0) AS bp_save_pct
FROM matches m;

-- Player Performance Table
-- Aggregates wins, aces, first serve %, hand domination (win rate by hand), double faults, BP save %.

CREATE OR REPLACE TABLE player_performance AS
SELECT 
    player_name,
    hand,
    COUNT(*) AS total_matches,
    SUM(is_win) AS wins,
    wins/total_matches as win_rate,
    SUM(aces) AS total_aces,
    SUM(double_faults) AS total_double_faults,
    AVG(first_serve_pct) AS avg_first_serve_pct,
    AVG(bp_save_pct) AS avg_bp_save_pct
FROM player_matches_view
GROUP BY player_name, hand
HAVING total_matches > 50
order by win_rate desc;  -- Filter for significant players

select * from player_performance;

-- Hand domination (separate query for win rate by hand)
SELECT 
    hand,
    AVG(is_win) AS win_rate,
    SUM(is_win) AS total_wins_by_hand
FROM player_matches_view
GROUP BY hand;


-- Age groups and win rate over years.
CREATE OR REPLACE TABLE age_impact AS
SELECT 
    year,
    ROUND(age) AS age_group,
    AVG(is_win) AS win_rate,
    COUNT(*) AS matches,
    AVG(first_serve_pct) AS avg_first_serve_pct_by_age
FROM player_matches_view
GROUP BY year, age_group
ORDER BY year, age_group;

-- Yearly wins, aces, etc., for top players.

CREATE OR REPLACE TABLE player_yearly_performance AS
SELECT 
    player_name,
    year,
    COUNT(*) AS matches,
    SUM(is_win) AS wins,
    wins / matches as win_percentage,
    SUM(aces) AS aces,
    AVG(first_serve_pct) AS avg_first_serve_pct,
    AVG(bp_save_pct) AS avg_bp_save_pct
FROM player_matches_view
GROUP BY player_name, year
HAVING matches > 20
ORDER BY player_name, year;  -- Significant yearly activity

-- Performance by tourney_level (G=Grand Slam, M=Masters 1000, A=ATP 250/500, F=Finals, D=Davis Cup). 

CREATE OR REPLACE TABLE tournament_trends AS
SELECT 
    player_name,
    CASE 
        WHEN tourney_level = 'G' THEN 'Grand Slam'
        WHEN tourney_level = 'M' THEN 'Masters 1000'
        WHEN tourney_level = 'A' AND draw_size <= 32 THEN 'ATP 250'
        WHEN tourney_level = 'A' AND draw_size > 32 THEN 'ATP 500'
        ELSE 'Other'
    END AS level_group,
    COUNT(*) AS matches,
    SUM(is_win) AS wins,
    SUM(is_win) / count(*) as win_percent
    
FROM player_matches_view
GROUP BY player_name, level_group
HAVING matches > 10
ORDER BY win_percent DESC;



