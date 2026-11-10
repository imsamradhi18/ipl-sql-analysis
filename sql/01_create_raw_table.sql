/* 
   IPL ANALYSIS (2008-2026)  |  PostgreSQL
   
   File     : 01_create_raw_table.sql
   Purpose  : Start from a clean slate and create the RAW landing table.
   Run order: 01 -> import CSV (see below) -> 02 -> 03 -> 04 -> 05
   Source   : Kaggle "IPL Dataset" (IPL.csv), ball-by-ball data compiled from
              Cricsheet. One row = one delivery. 64 columns.
*/

/* 
   STEP 1: Drop everything this project creates, so the script is re-runnable.
           Order matters: views first, then child tables, then parent tables.
*/
DROP VIEW  IF EXISTS deliveries_clean;
DROP VIEW  IF EXISTS matches_clean;
DROP TABLE IF EXISTS team_names;
DROP TABLE IF EXISTS deliveries;
DROP TABLE IF EXISTS matches;
DROP TABLE IF EXISTS ipl_raw;


/* 
   STEP 2: Create the raw table.
           Every column is TEXT on purpose. The CSV mixes date formats, blanks
           and TRUE/FALSE flags, so loading as text means the import cannot fail
           on data types. Proper types are applied later in 02_build_core_tables.sql.
           "over" is quoted because OVER is a reserved word in SQL.
           Column order matches the CSV exactly (required by the import).
*/
CREATE TABLE ipl_raw (
    match_id TEXT, date TEXT, match_type TEXT, event_name TEXT, innings TEXT,
    batting_team TEXT, bowling_team TEXT, "over" TEXT, ball TEXT, ball_no TEXT,
    batter TEXT, bat_pos TEXT, runs_batter TEXT, balls_faced TEXT, bowler TEXT,
    valid_ball TEXT, runs_extras TEXT, runs_total TEXT, runs_bowler TEXT,
    runs_not_boundary TEXT, extra_type TEXT, non_striker TEXT, non_striker_pos TEXT,
    wicket_kind TEXT, player_out TEXT, fielders TEXT, runs_target TEXT,
    review_batter TEXT, team_reviewed TEXT, review_decision TEXT, umpire TEXT,
    umpires_call TEXT, player_of_match TEXT, match_won_by TEXT, win_outcome TEXT,
    toss_winner TEXT, toss_decision TEXT, venue TEXT, city TEXT, day TEXT,
    month TEXT, year TEXT, season TEXT, gender TEXT, team_type TEXT,
    superover_winner TEXT, result_type TEXT, method TEXT, balls_per_over TEXT,
    overs TEXT, event_match_no TEXT, stage TEXT, match_number TEXT, team_runs TEXT,
    team_balls TEXT, team_wicket TEXT, new_batter TEXT, power_surge_start TEXT,
    batter_runs TEXT, batter_balls TEXT, bowler_wicket TEXT, batting_partners TEXT,
    striker_out TEXT, next_batter TEXT
);


/* -----------------------------------------------------------------------------
   STEP 3 (MANUAL): Import the CSV using pgAdmin.
     1. Right-click ipl_raw -> Import/Export Data...
     2. Switch to "Import"; Filename = <project folder>\data\IPL.csv
     3. Format = csv
     4. Options tab: Header = ON, Delimiter = , (comma)
     5. Click OK and wait for the import to finish (about 107 MB).

   Then verify (expect about 295,732 rows; 295,733 if the header got imported):
       SELECT COUNT(*) FROM ipl_raw;
   -------------------------------------------------------------------------- */
