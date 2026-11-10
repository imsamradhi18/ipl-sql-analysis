# Data Notes

Every data issue found while preparing the IPL dataset, what was observed, and how it was handled. Raw data (`ipl_raw`) is never modified except for removing the header row.

## 1. Source and coverage

- Kaggle "IPL Dataset" (`IPL.csv`), compiled from Cricsheet. 64 columns, one row per delivery.
- After cleaning: 295,732 deliveries, 1,243 matches, 19 seasons (2008 to 2026).
- The Kaggle notebook that uses this dataset is titled "2008-2025", but the data contains a 2026 season (74 matches). It is kept and reported as is.

## 2. Header row imported as data

- **Observed:** row count was 295,733 and a "season" value equal to the text `season` appeared (1 row).
- **Handled:** `DELETE FROM ipl_raw WHERE match_id = 'match_id'`. In the rebuilt pipeline the import skipped the header (295,732 rows) and the same statement deletes 0 rows.

## 3. Date formats

- **Observed:** dates appear as both `DD-MM-YYYY` (for example 18-04-2008) and `YYYY-MM-DD`. A first attempt with a single format failed with a date out-of-range error.
- **Handled:** `CASE` on the pattern, then `::DATE` or `TO_DATE(..., 'DD-MM-YYYY')`.

## 4. Season labels

- **Observed:** 20 distinct season values, including `2007/08`, `2009/10` and `2020/21`.
- **Handled:** mapped to the year the edition was played (2008, 2010, 2020), giving 19 seasons.

## 5. Matches with no winner

- **Observed:** `match_won_by` stored as the text `'Unknown'` for 25 matches: 16 ties and 9 no results.
- **Handled:** converted to `NULL`; `result_type` records the reason. Win-percentage calculations count these matches as played but not won. Win counts in the analysis use 1,218 decided matches.
- **Not analysed:** super-over winners for tied matches are stored in `superover_winner`; this column is kept but not used in the 15 queries.

## 6. Super overs

- **Observed:** innings 3 to 6 exist (86 + 77 + 8 + 4 = 175 balls). Innings 1 and 2 hold 153,254 and 142,303 balls.
- **Handled:** `is_super_over` flag (`innings > 2`). Player statistics and team phase rates exclude these balls, as official records do.

## 7. Renamed franchises

Mapped to current names in `team_names`; views `matches_clean` and `deliveries_clean` apply the mapping.

| Old name | Current name |
|---|---|
| Delhi Daredevils | Delhi Capitals |
| Kings XI Punjab | Punjab Kings |
| Royal Challengers Bangalore | Royal Challengers Bengaluru |
| Rising Pune Supergiants | Rising Pune Supergiant |

Result: 15 franchises. **Deliberately not merged** because they are different franchises: Deccan Chargers and Sunrisers Hyderabad; Gujarat Lions and Gujarat Titans; Rising Pune Supergiant and Pune Warriors.

## 8. Stadium names

- **Observed:** the same stadium stored under several spellings (a check grouping venues by city found 16 cities with more than one name). Examples: `MA Chidambaram Stadium` with and without ", Chepauk" and ", Chennai"; `Feroz Shah Kotla` (renamed Arun Jaitley Stadium); `Sardar Patel Stadium, Motera` (renamed Narendra Modi Stadium).
- **Handled:** mapping table `venue_names` and an updated `matches_clean` view (`sql/03b_venue_names.sql`). A second check by venue and city found one more duplicate, `M Chinnaswamy Stadium` (Bangalore) vs `M Chinnaswamy Stadium, Bengaluru`, now merged into 104 matches.
- **Left as is:** the same venue sometimes has different city labels (Dr DY Patil Sports Academy: Mumbai and Navi Mumbai; Maharaja Yadavindra Singh Stadium: Mohali and New Chandigarh; Dubai and Sharjah stadiums: city `Unknown`). Venue-level queries group by venue name, so these are unaffected.
- **Not merged:** different stadiums in the same city (Brabourne, Wankhede and DY Patil in Mumbai; Dubai vs Sharjah).

## 9. Column conventions

- `over_no` is zero-based: 0 is the 1st over, 19 is the 20th. Powerplay = 0 to 5, death overs = 15 to 19.
- `valid_ball = 1` for legal deliveries; `balls_faced = 0` for wides.
- `runs_bowler` is runs charged to the bowler (excludes byes and leg-byes).

## 10. Analysis choices

- Bowler wickets count caught, bowled, lbw, stumped, caught and bowled, and hit wicket. Run outs, retirements and obstructing the field are excluded, so totals can differ slightly from official sites.
- Thresholds: 500 balls faced (strike rate), 300 legal balls (economy), 10 matches (venue averages). These are my choices.
- "Matches played" per team counts matches in which the team batted (distinct `match_id` in the deliveries view).

## 11. Open items

- Summing matches played across the 15 teams gives 2,480, while 1,243 matches x 2 teams = 2,486. A 6-match difference is likely abandoned matches in which a team never batted, but this has not been verified.
- Season-by-season scoring trends were not analysed, so comparisons across eras (economy, venue averages) carry that limitation.
