/* =============================================================================
   IPL ANALYSIS (2008-2026)  |  PostgreSQL
   -----------------------------------------------------------------------------
   File     : 02_build_core_tables.sql
   Purpose  : Turn the flat raw table into two clean, typed tables:
                matches    -> one row per match
                deliveries -> one row per ball
              and link them with a primary key / foreign key.
   Run after: 01_create_raw_table.sql + CSV import
   Design   : The raw file repeats match details on every ball. Splitting it
              removes that repetition (normalisation) and makes JOINs meaningful.
   ========================================================================== */


/* -----------------------------------------------------------------------------
   STEP 1: Remove the header row if it was imported as data.
           Safe to run either way: it deletes 1 row if the header was loaded
           as data, and 0 rows if the import already skipped it.
   -------------------------------------------------------------------------- */
DELETE FROM ipl_raw WHERE match_id = 'match_id';


/* -----------------------------------------------------------------------------
   STEP 2: Build MATCHES (expected: 1,243 rows, one per match).

   Data issues handled here:
   a) Dates come in two formats, 'DD-MM-YYYY' and 'YYYY-MM-DD'. Both are
      converted to a real DATE.
   b) Season labels are inconsistent: '2007/08', '2009/10' and '2020/21' are
      stored as split-year labels. They are standardised to the year the IPL
      edition was played: 2008, 2010, 2020.
   c) Matches with no winner (ties and no-results) store the text 'Unknown'.
      This is converted to NULL, which is the proper way to say "no value".
      result_type still tells us WHY there is no winner.
   d) DISTINCT ON (match_id) keeps one row per match from the ball-by-ball data.
   -------------------------------------------------------------------------- */
CREATE TABLE matches AS
SELECT DISTINCT ON (ipl_raw.match_id)
    ipl_raw.match_id::INT AS match_id,
    CASE
        WHEN ipl_raw.date LIKE '____-__-__' THEN ipl_raw.date::DATE
        ELSE TO_DATE(ipl_raw.date, 'DD-MM-YYYY')
    END AS match_date,
    CASE ipl_raw.season
        WHEN '2007/08' THEN 2008
        WHEN '2009/10' THEN 2010
        WHEN '2020/21' THEN 2020
        ELSE ipl_raw.season::INT
    END AS season,
    event_name,
    stage,
    venue,
    city,
    toss_winner,
    toss_decision,
    player_of_match,
    NULLIF(NULLIF(match_won_by, ''), 'Unknown') AS match_won_by,
    win_outcome,
    result_type,
    NULLIF(superover_winner, '') AS superover_winner
FROM ipl_raw
ORDER BY ipl_raw.match_id;


/* -----------------------------------------------------------------------------
   STEP 3: Build DELIVERIES (expected: 295,732 rows, one per ball).

   - Numeric columns are cast from TEXT to INT.
   - Empty strings in wicket/extra columns become NULL.
   - over_no is ZERO-based in this dataset: over_no 0 is the 1st over,
     over_no 19 is the 20th over.
   - is_super_over flags innings 3 and above (super overs), so career statistics
     can exclude them, as cricket record books do.
   - valid_ball = 1 for a legal delivery (wides and no-balls are 0).
   - balls_faced = 1 when the batter faced a legal ball (wides are 0).
   - runs_bowler = runs charged to the bowler (excludes byes and leg-byes).
   -------------------------------------------------------------------------- */
CREATE TABLE deliveries AS
SELECT
    match_id::INT           AS match_id,
    innings::INT            AS innings,
    (innings::INT > 2)      AS is_super_over,
    batting_team,
    bowling_team,
    "over"::INT             AS over_no,
    ball::INT               AS ball,
    batter,
    bowler,
    non_striker,
    runs_batter::INT        AS runs_batter,
    runs_extras::INT        AS runs_extras,
    runs_total::INT         AS runs_total,
    runs_bowler::INT        AS runs_bowler,
    balls_faced::INT        AS balls_faced,
    valid_ball::INT         AS valid_ball,
    NULLIF(extra_type, '')  AS extra_type,
    NULLIF(wicket_kind, '') AS wicket_kind,
    NULLIF(player_out, '')  AS player_out,
    NULLIF(fielders, '')    AS fielders
FROM ipl_raw;


/* -----------------------------------------------------------------------------
   STEP 4: Keys and indexes.
   - PRIMARY KEY makes match_id unique in matches.
   - FOREIGN KEY guarantees every delivery belongs to a real match.
   - Indexes speed up the JOIN and GROUP BY columns used in the analysis
     (about 295k rows, so this makes queries noticeably faster).
   -------------------------------------------------------------------------- */
ALTER TABLE matches ADD PRIMARY KEY (match_id);

ALTER TABLE deliveries
    ADD CONSTRAINT fk_deliveries_match
    FOREIGN KEY (match_id) REFERENCES matches (match_id);

CREATE INDEX idx_deliveries_match  ON deliveries (match_id);
CREATE INDEX idx_deliveries_batter ON deliveries (batter);
CREATE INDEX idx_deliveries_bowler ON deliveries (bowler);
CREATE INDEX idx_matches_season    ON matches (season);

ANALYZE matches;
ANALYZE deliveries;
