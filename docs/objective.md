# Project Objective

## Goal

Use SQL on raw ball-by-ball IPL data (2008-2026) to answer practical cricket questions, and document the complete analyst workflow: load, inspect, clean, model, verify, analyse.

## Why this project

Raw data is rarely analysis-ready. This project shows that I can turn a flat 64-column file into a trustworthy relational model, find and fix data problems before they distort results, and then answer business-style questions with SQL.

## Questions the analysis answers

**Teams and match trends**
1. How many matches were played in each season?
2. Which teams are the most successful by win percentage, not just total wins?
3. Does winning the toss improve the chance of winning?
4. After winning the toss, is it better to bat or to field?
5. Who has won the most Player of the Match awards?

**Batting**
6. Who are the all-time top run scorers?
7. Who scores fastest (strike rate, minimum 500 balls)?
8. Who has hit the most sixes?
9. Who was the top run scorer in each season?

**Bowling**
10. Who are the top wicket takers?
11. Who are the most economical bowlers (minimum 300 legal balls)?

**Match strategy**
12. Which teams score fastest in the powerplay and at the death?
13. Which rivalries have been played most, and who leads each?
14. Do teams win more by batting first or chasing?
15. Which venues are the highest scoring?

## Data

Kaggle "IPL Dataset" (`IPL.csv`), compiled from Cricsheet. One row per delivery, 64 columns, 295,732 deliveries across 1,243 matches and 19 seasons.

## Approach

1. Load the CSV into a raw table where every column is text, so the import cannot fail on types.
2. Split it into `matches` and `deliveries` with proper data types, keys and indexes.
3. Standardise renamed teams and duplicate stadium names with mapping tables and views, leaving raw data untouched.
4. Verify the data with row counts, orphan checks and cross-checks (see `sql/04_data_quality_checks.sql`).
5. Answer the 15 questions in `sql/05_analysis_queries.sql`.

## Deliverables

SQL scripts (run in order), data notes, and the findings summarised in the README.
