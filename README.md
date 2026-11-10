# IPL Analysis (2008-2026) with PostgreSQL

An end-to-end SQL project: raw ball-by-ball IPL data is loaded, cleaned, remodelled into a relational schema, quality-checked, and then analysed with 15 queries covering teams, batting, bowling and match strategy.

**At a glance:** 1,243 matches | 295,732 deliveries | 19 seasons | 15 franchises | PostgreSQL 18

---

## Objective

Answer practical cricket questions from raw data using SQL only, and show the full workflow an analyst follows: load, inspect, clean, model, verify, analyse, document. See [docs/objective.md](docs/objective.md).

## Data

- **Source:** Kaggle "IPL Dataset" (`IPL.csv`), compiled from [Cricsheet](https://cricsheet.org) ball-by-ball data. It is the dataset used by the notebook [Indian Premier League Analysis (2008-2025)](https://www.kaggle.com/code/arbazkhan971/indian-premier-league-analysis-2008-2025) on Kaggle.
- **Size:** one file, 64 columns, one row per delivery (about 107 MB).
- **Not included in this repo** because it exceeds GitHub's file-size limit. Download it from Kaggle and place it at `data/IPL.csv` (see [data/README.md](data/README.md)).

## Tools

PostgreSQL 18, pgAdmin 4 (SQL editor and CSV import).

## Repository structure

```
ipl-sql-analysis/
├── README.md
├── docs/
│   ├── objective.md             what the project asks and why
│   └── data_notes.md            every data issue found and how it was handled
├── sql/
│   ├── 01_create_raw_table.sql  raw landing table (all TEXT)
│   ├── 02_build_core_tables.sql matches + deliveries, keys, indexes
│   ├── 03_team_names_and_views.sql  team rename mapping + clean views
│   ├── 03b_venue_names.sql      stadium name mapping + updated view
│   ├── 04_data_quality_checks.sql   checks with expected results
│   ├── 04b_my_verification_checks.sql   my own checks while verifying
│   └── 05_analysis_queries.sql  15 analysis queries
└── data/
    └── README.md                where to download IPL.csv
```

## How to reproduce

1. Create a PostgreSQL database called `ipl`.
2. Download `IPL.csv` from Kaggle into `data/`.
3. Run `sql/01_create_raw_table.sql`.
4. In pgAdmin, import `IPL.csv` into `ipl_raw` (Format: csv, Header: on, Delimiter: comma).
5. Run `02`, `03`, `03b` in order.
6. Run `04` and compare each result with its "Expected" comment.
7. Run the queries in `05` one at a time.

## Data model

`ipl_raw` (flat file, 64 text columns) is split into:

- **matches**: one row per match (1,243 rows), primary key `match_id`
- **deliveries**: one row per ball (295,732 rows), foreign key `match_id`
- **team_names**, **venue_names**: mapping tables (old name to current name)
- **matches_clean**, **deliveries_clean**: views that apply the mappings, so analysis queries need no repeated cleaning logic

## Data cleaning (summary)

| Issue found | How it was handled |
|---|---|
| Header row imported as data (295,733 rows) | Removed with a targeted `DELETE` |
| Two date formats (`DD-MM-YYYY`, `YYYY-MM-DD`) | `CASE` + `TO_DATE` into a real `DATE` |
| Split-year season labels (`2007/08`, `2009/10`, `2020/21`) | Mapped to 2008, 2010, 2020 |
| Winner stored as text `'Unknown'` for 25 matches (16 ties, 9 no results) | Converted to `NULL`; `result_type` keeps the reason |
| Renamed franchises (Delhi, Punjab, Bengaluru, Pune) | Mapping table + view, raw data untouched |
| Same stadium under several spellings | Mapping table + view (for example Chinnaswamy: 65 + 39 rows merged into 104 matches) |
| Super overs mixed with normal innings (175 balls) | `is_super_over` flag; excluded from player statistics |

Full detail: [docs/data_notes.md](docs/data_notes.md).

## Key findings

All numbers come from the queries in `sql/05_analysis_queries.sql`.

**Teams and match trends**

1. **Win rate (Q2).** Chennai Super Kings have the best record among established teams (148 wins in 265 matches, 55.8%). Mumbai Indians have the most wins (155) but a 53.3% win rate. Gujarat Titans lead at 61.0% but from only 77 matches.
2. **Toss (Q3).** Toss winners won 51.6% of decided matches (628 of 1,218), so the toss alone gives little edge.
3. **Bat or field (Q4).** After winning the toss, teams that chose to field won 54.7% (810 matches) and teams that chose to bat won 45.3% (408 matches). Captains chose to field about two times out of three.
4. **Chase vs defend (Q14).** Chasing teams won 54.7% of decided matches (666) against 45.3% for teams batting first (552). This matches the toss result above.
5. **Player of the Match (Q5).** AB de Villiers leads with 25 awards, ahead of CH Gayle and V Kohli (22 each).

**Batting**

6. **Runs (Q6).** V Kohli leads with 9,336 runs, 2,007 ahead of RG Sharma (7,329). AB de Villiers is 10th in runs (5,162) but first in Player of the Match awards.
7. **Strike rate (Q7, minimum 500 balls).** TH David (177.08), PD Salt (174.48) and AD Russell (174.18) lead. Russell sustains this over 1,522 balls.
8. **Sixes (Q8).** CH Gayle hit 357, 33 more than RG Sharma (324).
9. **Season top scorers (Q9).** 15 different batters led the 19 seasons. V Kohli's 973 runs in 2016 is the highest season total; DA Warner topped three seasons.

**Bowling**

10. **Wickets (Q10).** YS Chahal leads with 233, then B Kumar (226) and SP Narine (207). Seven of the top 10 are spinners.
11. **Economy (Q11, minimum 300 legal balls).** A Kumble (6.58), GD McGrath (6.61) and M Muralitharan (6.68) lead. SP Narine holds 6.79 across 4,651 balls, the largest sample in the top 10.

**Match strategy**

12. **Powerplay vs death overs (Q12).** Every team except Kochi Tuskers Kerala scores faster at the death than in the powerplay (gap from 0.65 to 2.66 runs per over). Royal Challengers Bengaluru show the largest gap: 7.97 in the powerplay, 10.63 at the death.
13. **Head-to-head (Q13).** Mumbai Indians lead five of the ten most-played rivalries, including 25-12 against Kolkata Knight Riders. Chennai vs Mumbai is the most-played pairing (41 matches, 21-20 to Mumbai).
14. **Venues (Q15, minimum 10 matches).** Dharamsala has the highest first-innings average (191.2, 19 matches). Among venues with larger samples, Narendra Modi Stadium (180.7, 53 matches) is highest.

## Skills demonstrated

Relational schema design (primary and foreign keys, indexes), `JOIN` (inner and left), CTEs, window functions (`ROW_NUMBER`, `SUM() OVER`), conditional aggregation (`CASE`, `FILTER`), `HAVING` thresholds, mapping tables and views for data cleaning, and systematic data validation.

## Limitations

- Player statistics exclude super overs; bowler wickets count only bowler-credited dismissals (caught, bowled, lbw, stumped, caught and bowled, hit wicket).
- Minimum-ball thresholds (500 for strike rate, 300 for economy) are my choice; other thresholds would change the lists.
- Averages and rankings span 19 seasons with different scoring eras, so economy and venue comparisons favour or penalise different periods.
- Small samples (for example Gujarat Titans, Dharamsala) should be read with caution.

## Author

SAMRADHI PALIWAL | https://www.linkedin.com/in/samradhi-paliwal/ | psamradhi.18@gmail.com
