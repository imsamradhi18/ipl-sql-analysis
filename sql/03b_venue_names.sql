/* =============================================================================
   IPL ANALYSIS (2008-2026)  |  PostgreSQL
   -----------------------------------------------------------------------------
   File     : 03b_venue_names.sql
   Purpose  : Merge duplicate stadium names so each stadium appears ONCE.
   Run after: 03_team_names_and_views.sql
   Finding  : A data-quality check (grouping venues by city) showed the same
              stadium stored under several spellings, for example:
                - 'MA Chidambaram Stadium' / '..., Chepauk' / '..., Chepauk, Chennai'
                - 'Feroz Shah Kotla' (renamed Arun Jaitley Stadium)
                - 'Sardar Patel Stadium, Motera' (renamed Narendra Modi Stadium)
              Left alone, venue-level statistics would be split across rows.
   Method   : Same approach as team names: a mapping table (variant -> standard
              name) plus an updated view. Raw tables stay untouched.
   Not merged (genuinely different stadiums in the same city):
              Brabourne / Wankhede / DY Patil (Mumbai), Dubai vs Sharjah.
   ========================================================================== */


/* -----------------------------------------------------------------------------
   STEP 1: Mapping table. Only variant names are listed; any venue not listed
           keeps its name.
   -------------------------------------------------------------------------- */
DROP VIEW  IF EXISTS matches_clean;
DROP TABLE IF EXISTS venue_names;

CREATE TABLE venue_names (
    old_name     TEXT PRIMARY KEY,
    current_name TEXT NOT NULL
);

INSERT INTO venue_names (old_name, current_name) VALUES
    ('Zayed Cricket Stadium, Abu Dhabi',  'Sheikh Zayed Stadium'),
    ('Sardar Patel Stadium, Motera',      'Narendra Modi Stadium, Ahmedabad'),
    ('M Chinnaswamy Stadium',             'M Chinnaswamy Stadium, Bengaluru'),
    ('M.Chinnaswamy Stadium',             'M Chinnaswamy Stadium, Bengaluru'),
    ('Punjab Cricket Association IS Bindra Stadium, Mohali',
                                          'Punjab Cricket Association IS Bindra Stadium'),
    ('Punjab Cricket Association IS Bindra Stadium, Mohali, Chandigarh',
                                          'Punjab Cricket Association IS Bindra Stadium'),
    ('Punjab Cricket Association Stadium, Mohali',
                                          'Punjab Cricket Association IS Bindra Stadium'),
    ('MA Chidambaram Stadium, Chepauk',   'MA Chidambaram Stadium'),
    ('MA Chidambaram Stadium, Chepauk, Chennai', 'MA Chidambaram Stadium'),
    ('Arun Jaitley Stadium, Delhi',       'Arun Jaitley Stadium'),
    ('Feroz Shah Kotla',                  'Arun Jaitley Stadium'),
    ('Himachal Pradesh Cricket Association Stadium, Dharamsala',
                                          'Himachal Pradesh Cricket Association Stadium'),
    ('Rajiv Gandhi International Stadium, Uppal',
                                          'Rajiv Gandhi International Stadium'),
    ('Rajiv Gandhi International Stadium, Uppal, Hyderabad',
                                          'Rajiv Gandhi International Stadium'),
    ('Sawai Mansingh Stadium, Jaipur',    'Sawai Mansingh Stadium'),
    ('Eden Gardens, Kolkata',             'Eden Gardens'),
    ('Brabourne Stadium, Mumbai',         'Brabourne Stadium'),
    ('Dr DY Patil Sports Academy, Mumbai','Dr DY Patil Sports Academy'),
    ('Wankhede Stadium, Mumbai',          'Wankhede Stadium'),
    ('Maharaja Yadavindra Singh International Cricket Stadium, Mullanpur',
                                          'Maharaja Yadavindra Singh International Cricket Stadium'),
    ('Maharaja Yadavindra Singh International Cricket Stadium, New Chandigarh',
                                          'Maharaja Yadavindra Singh International Cricket Stadium'),
    ('Maharashtra Cricket Association Stadium, Pune',
                                          'Maharashtra Cricket Association Stadium'),
    ('Subrata Roy Sahara Stadium',        'Maharashtra Cricket Association Stadium'),
    ('Shaheed Veer Narayan Singh International Stadium, Raipur',
                                          'Shaheed Veer Narayan Singh International Stadium'),
    ('Dr. Y.S. Rajasekhara Reddy ACA-VDCA Cricket Stadium, Visakhapatnam',
                                          'Dr. Y.S. Rajasekhara Reddy ACA-VDCA Cricket Stadium');


/* -----------------------------------------------------------------------------
   STEP 2: Rebuild matches_clean with BOTH mappings (teams and venues).
           Column order is unchanged from 03, so every query keeps working.
   -------------------------------------------------------------------------- */
CREATE VIEW matches_clean AS
SELECT
    m.match_id,
    m.match_date,
    m.season,
    m.event_name,
    m.stage,
    COALESCE(v.current_name, m.venue)             AS venue,
    m.city,
    m.toss_decision,
    m.player_of_match,
    m.win_outcome,
    m.result_type,
    COALESCE(t1.current_name, m.toss_winner)      AS toss_winner,
    COALESCE(t2.current_name, m.match_won_by)     AS match_won_by,
    COALESCE(t3.current_name, m.superover_winner) AS superover_winner
FROM matches m
LEFT JOIN venue_names v ON m.venue            = v.old_name
LEFT JOIN team_names t1 ON m.toss_winner      = t1.old_name
LEFT JOIN team_names t2 ON m.match_won_by     = t2.old_name
LEFT JOIN team_names t3 ON m.superover_winner = t3.old_name;


/* -----------------------------------------------------------------------------
   STEP 3: Verify. Run on its own. Each stadium should now appear once.
           Expected: matches add up to 1243 and no stadium is repeated under
           two spellings.
   -------------------------------------------------------------------------- */
-- SELECT venue, COUNT(*) AS matches
-- FROM matches_clean
-- GROUP BY venue
-- ORDER BY venue;
