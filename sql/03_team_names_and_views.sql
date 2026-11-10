/* =============================================================================
   IPL ANALYSIS (2008-2026)  |  PostgreSQL
   -----------------------------------------------------------------------------
   File     : 03_team_names_and_views.sql
   Purpose  : Treat renamed franchises as ONE team, without changing raw data.
   Run after: 02_build_core_tables.sql

   Problem  : To a database, 'Delhi Daredevils' and 'Delhi Capitals' are just
              two different pieces of text, so one franchise's wins would be
              split across two rows.
   Solution : A small mapping table (old name -> current name) plus two views
              that JOIN to it. Original tables stay untouched, so the cleaning
              is transparent and reversible.
   ========================================================================== */


/* -----------------------------------------------------------------------------
   STEP 1: Mapping table. Only renamed teams are listed; every other team keeps
           its name.
           Deliberately NOT merged, because they are different franchises:
             - Deccan Chargers      vs Sunrisers Hyderabad
             - Gujarat Lions        vs Gujarat Titans
             - Rising Pune Supergiant vs Pune Warriors
   -------------------------------------------------------------------------- */
CREATE TABLE team_names (
    old_name     TEXT PRIMARY KEY,
    current_name TEXT NOT NULL
);

INSERT INTO team_names (old_name, current_name) VALUES
    ('Delhi Daredevils',            'Delhi Capitals'),
    ('Kings XI Punjab',             'Punjab Kings'),
    ('Royal Challengers Bangalore', 'Royal Challengers Bengaluru'),
    ('Rising Pune Supergiants',     'Rising Pune Supergiant');


/* -----------------------------------------------------------------------------
   STEP 2: matches_clean
           LEFT JOIN keeps every match. COALESCE means "use the current name if
           one exists, otherwise keep the original name".
           The mapping is applied to three columns: toss winner, match winner
           and super over winner.
   -------------------------------------------------------------------------- */
CREATE VIEW matches_clean AS
SELECT
    m.match_id,
    m.match_date,
    m.season,
    m.event_name,
    m.stage,
    m.venue,
    m.city,
    m.toss_decision,
    m.player_of_match,
    m.win_outcome,
    m.result_type,
    COALESCE(t1.current_name, m.toss_winner)      AS toss_winner,
    COALESCE(t2.current_name, m.match_won_by)     AS match_won_by,
    COALESCE(t3.current_name, m.superover_winner) AS superover_winner
FROM matches m
LEFT JOIN team_names t1 ON m.toss_winner      = t1.old_name
LEFT JOIN team_names t2 ON m.match_won_by     = t2.old_name
LEFT JOIN team_names t3 ON m.superover_winner = t3.old_name;


/* -----------------------------------------------------------------------------
   STEP 3: deliveries_clean
           Same idea for batting_team and bowling_team.
   -------------------------------------------------------------------------- */
CREATE VIEW deliveries_clean AS
SELECT
    d.match_id,
    d.innings,
    d.is_super_over,
    d.over_no,
    d.ball,
    d.batter,
    d.bowler,
    d.runs_batter,
    d.runs_extras,
    d.runs_total,
    d.runs_bowler,
    d.balls_faced,
    d.valid_ball,
    d.wicket_kind,
    d.player_out,
    COALESCE(b.current_name, d.batting_team) AS batting_team,
    COALESCE(w.current_name, d.bowling_team) AS bowling_team
FROM deliveries d
LEFT JOIN team_names b ON d.batting_team = b.old_name
LEFT JOIN team_names w ON d.bowling_team = w.old_name;
