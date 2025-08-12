# atp-analysis
ATP Tennis Data Analysis Project using Snowflake, Python, and Tableau

# ATP Tennis Analysis Project

Analyzes ATP tennis data (2000–2019) using Snowflake SQL, Snowpark Python, and Tableau.

## Data Source
- Source: [Jeff Sackmann’s ATP Tennis Repository](https://github.com/JeffSackmann/tennis_atp)
- License: Creative Commons Attribution-NonCommercial-ShareAlike 4.0
- Citation: Sackmann, J. (2025). ATP Tennis Rankings, Results, and Stats.
- Download `atp_players.csv`, `atp_matches_2000.csv` to `atp_matches_2019.csv`, and `matches_data_dictionary.txt` from the source.

## Setup
1. Download the ATP dataset from the source above.
2. Run `sql/ATP_Data_Preparation.sql` in Snowflake to load and clean data.
3. Run `sql/ATP_Analysis_Tables.sql` to create analysis tables.
4. Run `python/atp_analysis.ipynb` locally with Snowpark to generate CSVs (saved to `@tennis_stage`).
5. Download CSVs from Snowflake for Tableau visualizations.

## Notes
- CSVs are not included in this repository to comply with the CC BY-NC-SA 4.0 license.
- Use `config.json` (excluded via `.gitignore`) with your Snowflake credentials.

## License
This project is non-commercial, under CC BY-NC-SA 4.0.

