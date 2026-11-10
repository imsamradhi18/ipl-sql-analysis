/* =============================================================================
   IPL ANALYSIS (2008-2026)  |  PostgreSQL
   -----------------------------------------------------------------------------
   File     : 04_data_quality_checks.sql
   Purpose  : Prove the data is trustworthy BEFORE analysing it.
   Run after: 03_team_names_and_views.sql
   How      : Run each query on its own (select it, then press F5).
              Compare the result with the "Expected" note above it.
   ========================================================================== */


-- CHECK 1: Row counts of the core tables.
-- Expected: matches = 1243, deliveries = 295732, team_names = 4
SELECT 'matches'    AS table_name, COUNT(*) AS row_count FROM matches
UNION ALL
SELECT 'deliveries', COUNT(*) FROM deliveries
UNION ALL
SELECT 'team_names', COUNT(*) FROM team_names;


-- CHECK 2: Seasons covered and matches per season.
-- Expected: 19 rows, seasons 2008 to 2026, no split labels like '2007/08'.
SELECT season, COUNT(*) AS matches
FROM matches
GROUP BY season
ORDER BY season;


-- CHECK 3: Orphan deliveries (balls that point to a match that does not exist).
-- Expected: 0
SELECT COUNT(*) AS orphan_deliveries
FROM deliveries d
LEFT JOIN matches m ON m.match_id = d.match_id
WHERE m.match_id IS NULL;


-- CHECK 4: Distinct teams after merging renamed franchises.
-- Expected: 15 teams; no 'Delhi Daredevils', 'Kings XI Punjab' or
-- 'Royal Challengers Bangalore'.
SELECT batting_team, COUNT(DISTINCT match_id) AS matches_played
FROM deliveries_clean
GROUP BY batting_team
ORDER BY matches_played DESC;


-- CHECK 5: Why do some matches have no winner?
-- Expected: 25 rows in total, made up of 'tie' (16) and 'no result' (9).
SELECT result_type, COUNT(*) AS matches
FROM matches_clean
WHERE match_won_by IS NULL
GROUP BY result_type;


-- CHECK 6: Innings distribution (is_super_over relies on innings above 2).
-- Expected: innings 1 and 2 have almost all rows; any innings 3 or higher
-- are super overs.
SELECT innings, is_super_over, COUNT(*) AS balls
FROM deliveries
GROUP BY innings, is_super_over
ORDER BY innings;


-- CHECK 7: Tied matches and whether a super over winner is recorded.
SELECT result_type,
       COUNT(*)                  AS matches,
       COUNT(superover_winner)   AS with_superover_winner
FROM matches_clean
WHERE result_type = 'tie'
GROUP BY result_type;


-- CHECK 8: Venue names. Eyeball this list for the same stadium written two
-- ways (for example with and without the city name). If you find duplicates,
-- record them in your data notes before using venue-level analysis.
SELECT venue, city, COUNT(*) AS matches
FROM matches
GROUP BY venue, city
ORDER BY venue;
