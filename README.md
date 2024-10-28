# FPL Data Pipeline Project
![](https://fantasy.premierleague.com/img/share/facebook-share.png)

**An FPL data project using R, Github Actions and Tableau**

## Project overview ⚽
Diagram of data pipeline

## API & Webscrapping 🛜
It was chalolanging to find the documentation for the FPL API however i was able to find information through others that have already connect to it. 
My main source of information regarding the API was [https://www.game-change.co.uk/2023/02/10/a-complete-guide-to-the-fantasy-premier-league-fpl-api/#google_vignette.](https://www.oliverlooney.com/blogs/FPL-APIs-Explained)

Using the link a list of endpoints can be found with the data that is included in each endpoint. For the purpose of this project I did not use any endpoints that gave data regarding specific leagues or users teams.

The base URL is bootstrap-static/ and using the endpoints in the table returns you the fields stated in the table.
| End Point Used | Fields | Notes |
| ---- | ---- | ---- |
| bootsrap-static/<br><br>teams data |code<br>draw<br>form<br>id<br>loss<br>name<br>played<br>points<br>position<br>short_name<br>strength<br>team_division<br>unavailable<br>win<br>strength_overall_home<br>strength_overall_away<br>strength_attack_home<br>strength_attack_away<br>strength_defence_away<br>strength_defence_away<br>pulse_id | Many of the fields in this endpoint do not update. Hence the need for webscrapping the premier league standings table |
| fixtures/ | code<br>event<br>finished<br>finished_provisional<br>id<br>kickoff_time<br>minutes<br>provisional_start_time<br>started<br>team_a<br>team_a_score<br>team_h<br>team_h_score<br>stats<br>team_h_difficulty<br>team_a_difficulty<br>pulse_id |  |
|a|a|a|

## R Script ®️

## Github actions 🎬
In order to have the r script run automatically on a schedule I decided to use Github Actions. A YAML file is needed to create workflows.

Firstly a virtual machine is started and installs R and all the packages needed for the R Script to run.
specifying "runs-on: ubunto-latest" means that the virtual machine is running linux. Linus is the cheapest opperating system to run actions on and is more than adequate for the purpose of running the r script.
````yaml
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
````
Following on from loading the virtual machine up is the need to run R script saved in the repository
````yaml
      - name: FPL Code
        run : Rscript -e 'source("FPL_API.R")'
````
The r script creates csv files that need to be saved back to the repository before the virtual machine uninstalls and closes. The YAML code only updates the csv if there is an update from the file already saved in the repository
````yaml
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
