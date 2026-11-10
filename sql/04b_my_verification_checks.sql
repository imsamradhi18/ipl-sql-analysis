SELECT 'matches' AS table_name, COUNT(*) AS row_count FROM matches
UNION ALL
SELECT 'deliveries', COUNT(*) FROM deliveries;

SELECT COUNT(DISTINCT batting_team) AS total_teams
FROM deliveries_clean;

/*Super over check*/ 

SELECT innings, is_super_over, COUNT(*) AS balls
FROM deliveries
GROUP BY innings, is_super_over
ORDER BY innings;

/* Venue names check*/ 
SELECT city,
       COUNT(DISTINCT venue) AS venue_names,
       STRING_AGG(DISTINCT venue, ' | ') AS names
FROM matches
GROUP BY city
HAVING COUNT(DISTINCT venue) > 1
ORDER BY city;
/* check venue */ 
SELECT venue, city, COUNT(*) AS matches
FROM matches_clean
GROUP BY venue, city
ORDER BY venue;
