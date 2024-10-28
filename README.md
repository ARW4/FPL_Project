# FPL Data Pipeline Project
![](https://fantasy.premierleague.com/img/share/facebook-share.png)

**An FPL data project using R, Github Actions and Tableau**

## Project overview ⚽
Diagram of data pipeline

## API 🛜
It was chalolanging to find the documentation for the FPL API however i was able to find information through others that have already connect to it. 
My main source of information regarding the API was [https://www.game-change.co.uk/2023/02/10/a-complete-guide-to-the-fantasy-premier-league-fpl-api/#google_vignette.](https://www.oliverlooney.com/blogs/FPL-APIs-Explained)

Using the link a list of endpoints can be found with the data that is included in each endpoint. For the purpose of this project I did not use any endpoints that gave data regarding specific leagues or users teams.

## R Script ®️

## GIthub actions 🎬

````yml
name: schedule

on:
  schedule:
  - cron : "30 5 * * *"

jobs:
  import-data:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: r-lib/actions/setup-r@v2
      - uses: r-lib/actions/setup-renv@v2
      
      - name: FPL Code
        run : Rscript -e 'source("FPL_API.R")'

      - name: Commit results
        run: |
          git config --local user.email "actions@github.com"
          git config --local user.name "GitHub Actions"
          git add Standings.csv
          git add Player_Gameweek_Stats.csv
          git add Player_Historic_Stats.csv
          git add Player_Info.csv
          git add Fixtures.csv
          git commit -m 'Data updated' || echo "No changes to commit"
          git push origin || echo "No changes to commit"
````

## Tableau Dashboard 📊
