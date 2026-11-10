/* =============================================================================
   IPL ANALYSIS (2008-2026)  |  PostgreSQL
   -----------------------------------------------------------------------------
   File     : 05_analysis_queries.sql
   Purpose  : 15 business-style questions answered with SQL, from basic
              aggregations to JOINs, CTEs and window functions.
   Run after: 04_data_quality_checks.sql
   Notes    : - Run each query on its own (select it, then press F5).
              - All queries use the cleaned views (matches_clean, deliveries_clean),
                so renamed franchises are already merged.
              - Player statistics exclude super overs (is_super_over = FALSE),
                as official records do.
              - over_no is zero-based: 0 = 1st over, 19 = 20th over.
   Sections : A) Match and team trends   B) Batting   C) Bowling   D) Match strategy
   ========================================================================== */


/* #############################################################################
   SECTION A: MATCH AND TEAM TRENDS
   ########################################################################## */

-- Q1. How many matches were played in each season?
-- Approach: group matches by season and count.
-- Skills  : GROUP BY, COUNT
SELECT season, COUNT(*) AS matches
FROM matches_clean
GROUP BY season
ORDER BY season;


-- Q2. Which teams are the most successful, by win percentage and not just total wins?
-- Approach: count matches played and matches won per team in two CTEs, then join.
--           A team that played more seasons naturally has more wins, so the
--           percentage is the fairer measure. Ties and no-results count as
--           played but not won.
-- Skills  : CTE, LEFT JOIN, COALESCE, conditional maths
WITH played AS (
    SELECT batting_team AS team,
           COUNT(DISTINCT match_id) AS matches_played
    FROM deliveries_clean
    WHERE NOT is_super_over
    GROUP BY batting_team
),
won AS (
    SELECT match_won_by AS team,
           COUNT(*)     AS matches_won
    FROM matches_clean
    WHERE match_won_by IS NOT NULL
    GROUP BY match_won_by
)
SELECT p.team,
       p.matches_played,
       COALESCE(w.matches_won, 0) AS matches_won,
       ROUND(100.0 * COALESCE(w.matches_won, 0) / p.matches_played, 1) AS win_pct
FROM played p
LEFT JOIN won w ON w.team = p.team
ORDER BY win_pct DESC;


-- Q3. Does winning the toss improve the chance of winning the match?
-- Approach: among matches with a result, count how often the toss winner also
--           won. A figure near 50% means the toss gives no real edge.
-- Skills  : CASE WHEN inside SUM, percentage calculation
SELECT COUNT(*) AS matches_with_result,
       SUM(CASE WHEN toss_winner = match_won_by THEN 1 ELSE 0 END) AS toss_winner_won,
       ROUND(100.0 * SUM(CASE WHEN toss_winner = match_won_by THEN 1 ELSE 0 END)
             / COUNT(*), 1) AS toss_winner_win_pct
FROM matches_clean
WHERE match_won_by IS NOT NULL;


-- Q4. Is it better to bat or to field after winning the toss?
-- Approach: split Q3 by the toss decision.
-- Skills  : GROUP BY with conditional aggregation
SELECT toss_decision,
       COUNT(*) AS matches,
       ROUND(100.0 * SUM(CASE WHEN toss_winner = match_won_by THEN 1 ELSE 0 END)
             / COUNT(*), 1) AS toss_winner_win_pct
FROM matches_clean
WHERE match_won_by IS NOT NULL
GROUP BY toss_decision
ORDER BY matches DESC;


-- Q5. Who has won the most Player of the Match awards? (top 10)
-- Skills  : GROUP BY, ORDER BY, LIMIT
SELECT player_of_match, COUNT(*) AS awards
FROM matches_clean
WHERE player_of_match IS NOT NULL
GROUP BY player_of_match
ORDER BY awards DESC
LIMIT 10;


/* #############################################################################
   SECTION B: BATTING
   ########################################################################## */

-- Q6. Who are the all-time top 10 run scorers?
-- Skills  : SUM, GROUP BY
SELECT batter, SUM(runs_batter) AS total_runs
FROM deliveries_clean
WHERE NOT is_super_over
GROUP BY batter
ORDER BY total_runs DESC
LIMIT 10;


-- Q7. Who are the fastest scorers? (strike rate, minimum 500 balls faced)
-- Approach: strike rate = runs / balls faced x 100. The minimum-balls filter
--           (HAVING) stops players with a few lucky innings topping the list.
--           balls_faced is 0 for wides, so extras are handled correctly.
-- Skills  : HAVING, ROUND, ratio calculation
SELECT batter,
       SUM(runs_batter) AS runs,
       SUM(balls_faced) AS balls_faced,
       ROUND(100.0 * SUM(runs_batter) / SUM(balls_faced), 2) AS strike_rate
FROM deliveries_clean
WHERE NOT is_super_over
GROUP BY batter
HAVING SUM(balls_faced) >= 500
ORDER BY strike_rate DESC
LIMIT 10;


-- Q8. Who has hit the most sixes? (top 10)
-- Skills  : conditional COUNT with FILTER
SELECT batter,
       COUNT(*) FILTER (WHERE runs_batter = 6) AS sixes
FROM deliveries_clean
WHERE NOT is_super_over
GROUP BY batter
ORDER BY sixes DESC
LIMIT 10;


-- Q9. Who was the top run scorer (the "Orange Cap" winner) in each season?
-- Approach: total runs per batter per season, rank within each season, keep rank 1.
-- Skills  : JOIN, CTE, window function ROW_NUMBER() OVER (PARTITION BY ...)
WITH season_runs AS (
    SELECT m.season, d.batter, SUM(d.runs_batter) AS runs
    FROM deliveries_clean d
    JOIN matches_clean m ON m.match_id = d.match_id
    WHERE NOT d.is_super_over
    GROUP BY m.season, d.batter
),
ranked AS (
    SELECT season, batter, runs,
           ROW_NUMBER() OVER (PARTITION BY season ORDER BY runs DESC, batter) AS rn
    FROM season_runs
)
SELECT season, batter, runs
FROM ranked
WHERE rn = 1
ORDER BY season;


/* #############################################################################
   SECTION C: BOWLING
   ########################################################################## */

-- Q10. Who are the top 10 wicket takers?
-- Approach: only dismissals credited to the bowler are counted. Run outs,
--           retirements and obstructing the field are NOT bowler wickets.
-- Skills  : IN list filter, GROUP BY
SELECT bowler, COUNT(*) AS wickets
FROM deliveries_clean
WHERE NOT is_super_over
  AND wicket_kind IN ('caught', 'bowled', 'lbw', 'stumped',
                      'caught and bowled', 'hit wicket')
GROUP BY bowler
ORDER BY wickets DESC
LIMIT 10;


-- Q11. Who are the most economical bowlers? (minimum 300 legal balls)
-- Approach: economy = runs conceded per over. runs_bowler excludes byes and
--           leg-byes, and valid_ball counts only legal deliveries (6 per over).
-- Skills  : HAVING, ratio calculation
SELECT bowler,
       SUM(valid_ball)   AS legal_balls,
       SUM(runs_bowler)  AS runs_conceded,
       ROUND(SUM(runs_bowler) / (SUM(valid_ball) / 6.0), 2) AS economy
FROM deliveries_clean
WHERE NOT is_super_over
GROUP BY bowler
HAVING SUM(valid_ball) >= 300
ORDER BY economy ASC
LIMIT 10;


/* #############################################################################
   SECTION D: MATCH STRATEGY
   ########################################################################## */

-- Q12. Which teams score fastest in the powerplay (overs 1-6) and at the death
--      (overs 16-20)?
-- Approach: runs per over = 6 x runs / legal balls, calculated separately for
--           each phase. over_no 0-5 are overs 1-6; 15-19 are overs 16-20.
-- Skills  : conditional aggregation (CASE inside SUM)
SELECT batting_team,
       ROUND(6.0 * SUM(CASE WHEN over_no BETWEEN 0 AND 5   THEN runs_total END)
                 / SUM(CASE WHEN over_no BETWEEN 0 AND 5   THEN valid_ball END), 2) AS powerplay_run_rate,
       ROUND(6.0 * SUM(CASE WHEN over_no BETWEEN 15 AND 19 THEN runs_total END)
                 / SUM(CASE WHEN over_no BETWEEN 15 AND 19 THEN valid_ball END), 2) AS death_run_rate
FROM deliveries_clean
WHERE NOT is_super_over
GROUP BY batting_team
ORDER BY death_run_rate DESC;


-- Q13. Head-to-head records: which rivalries have been played most often, and
--      who leads each?
-- Approach: find the two teams in every match (alphabetical min and max of the
--           batting teams), join to the match result, then count wins per side.
-- Skills  : CTE, JOIN ... USING, MIN/MAX on text, conditional aggregation
WITH match_teams AS (
    SELECT match_id,
           MIN(batting_team) AS team_a,
           MAX(batting_team) AS team_b
    FROM deliveries_clean
    WHERE NOT is_super_over
    GROUP BY match_id
)
SELECT mt.team_a,
       mt.team_b,
       COUNT(*) AS matches_played,
       SUM(CASE WHEN mc.match_won_by = mt.team_a THEN 1 ELSE 0 END) AS team_a_wins,
       SUM(CASE WHEN mc.match_won_by = mt.team_b THEN 1 ELSE 0 END) AS team_b_wins
FROM match_teams mt
JOIN matches_clean mc USING (match_id)
GROUP BY mt.team_a, mt.team_b
ORDER BY matches_played DESC
LIMIT 10;


-- Q14. Do teams win more often by batting first or by chasing?
-- Approach: identify the team that batted in innings 1 of each match, then
--           check whether that team was also the match winner.
-- Skills  : CTE, JOIN, CASE WHEN
WITH batted_first AS (
    SELECT DISTINCT match_id, batting_team
    FROM deliveries_clean
    WHERE innings = 1
)
SELECT CASE WHEN bf.batting_team = mc.match_won_by
            THEN 'Batting first won'
            ELSE 'Chasing team won' END AS outcome,
       COUNT(*) AS matches,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM matches_clean mc
JOIN batted_first bf ON bf.match_id = mc.match_id
WHERE mc.match_won_by IS NOT NULL
GROUP BY outcome
ORDER BY matches DESC;


-- Q15. Which venues are the highest scoring? (average first-innings score,
--      venues with at least 10 matches)
-- Approach: total each match's first innings, join to the venue, average per venue.
-- Caveat  : if CHECK 8 in 04_data_quality_checks.sql showed the same stadium
--           under two names, merge them before trusting this result.
-- Skills  : CTE, JOIN, AVG, HAVING
WITH first_innings AS (
    SELECT match_id, SUM(runs_total) AS score
    FROM deliveries_clean
    WHERE innings = 1
    GROUP BY match_id
)
SELECT m.venue,
       COUNT(*)                 AS matches,
       ROUND(AVG(f.score), 1)   AS avg_first_innings_score
FROM first_innings f
JOIN matches_clean m ON m.match_id = f.match_id
GROUP BY m.venue
HAVING COUNT(*) >= 10
ORDER BY avg_first_innings_score DESC
LIMIT 10;
