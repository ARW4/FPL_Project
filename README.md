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
| End Point Used | Notes |
|---- |---- |
|element-summary/"{id}"//|used to retrieve data on players throughout the current and previous season.<br>Data for current season is at the matchday level, whilst data for historic seasons is aggregated to the season level.|
|bootstrap-static/|used to get an overview of teams and player info.|
|fixtures/|returns all the data regarding all completed and future matches.|

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
