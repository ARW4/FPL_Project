# FPL Data Pipeline Project
<img width="1000" alt="Data Pipeline Diagram" src="https://github.com/user-attachments/assets/0c6f0ff0-00e0-47eb-aa64-c0643a3f337a">

## Project overview ⚽
The aim of this project was to create a complete end to end data pipeline that would have fully fully automated data refreshes. 
<br><br>
This read me outlines the process of making this happen and also some of the challanges along the way. If you would like to skip straight to the dashboard use the link [here](https://public.tableau.com/app/profile/alexrwood/viz/FPLDashboard_17254712584930/FPL-HiddenGems).

## Contents 📖
[API](#API)
<br>[Webscrapping](#Web-Scraping)
<br>[R Packages](#R-packages)
<br>[API Call (R Script)](#API-Call)
<br>[Looping API Call (R Script)](#Looping-API-Call)
<br>[Web Scraping (R Script)](#Web-Scraping)
<br>[Github Actions](#Github-Actions)
<br>[Tableau Dashboard](#FPL-Dashboard)

## Data Sources 🛜
### API
It was a challeng to find the documentation for the FPL API, however I was able to find information through others that have already connect to it.

There are a variety of different endpoints available. The list of the endpoints I used are in the table below, however for a more extensive list of endpoints use the link below.

[https://www.game-change.co.uk/2023/02/10/a-complete-guide-to-the-fantasy-premier-league-fpl-api/#google_vignette.](https://www.oliverlooney.com/blogs/FPL-APIs-Explained)

The base URL is bootstrap-static/ and using the endpoints in the table returns you the fields stated in the table.
| End Point Used | Notes |
|---- |---- |
|element-summary/"{id}"//|used to retrieve data on players throughout the current and previous season.<br>Data for current season is at the matchday level, whilst data for historic seasons is aggregated to the season level.|
|bootstrap-static/|used to get an overview of teams and player info.|
|fixtures/|returns all the data regarding all completed and future matches.|

### Web Scraping
The API that returns data regarding the current league standings was not successfully giving updated data. Given this situation I decided to retrieve the premier league standings table through webscraping in R.
After looking through a few options the website that gave the data in the kindest format was the bbc webiste (https://www.bbc.co.uk/sport/football/premier-league/table)

## R Script ®️
### R Packages
The below table shows the packages that were used for this project and a breif note on the purpose and use that the packages had.
| R Package | Useage |
|---- |---- | 
| conflicted | Used to resolve conflicts from functions between packages |
| httr | Used for making API Calls |
| jsonlite | Converts json into R objects | 
| tidyverse | collection of packages that help with transforming data |
| progress | Creates a progress bar, used when looping through API calls |
| rvest | Used for webscraping data |
### API Call
To extract data from the endpoints the foollwing structure of r code was used.

Using the endpoint to make a "GET" API call. 
````r
res = VERB("GET", url = "https://fantasy.premierleague.com/api/fixtures/")
````

Converts the reponse of the API call into json
````r
res2 <- content(res, "text", encoding = "UTF-8")
````

Converts the response from JSON
````r
item <- fromJSON(res2)
````

Creates a data frame with the parsed JSON Data
````r
Fixtures <- data.frame(item)
````
This structure of making the API Call and converting the downloaded data into a data frame is used for all calls made in the project.

### Looping API Call
The endpoint used for retrieving the player stats is such that you can only call data from one player at a time using their player id. In order to download the data for all players possible it was neccessary to create a loop.<br>
1 - Using a pre-existing data frame that contained all the player IDs to create a new data frame
````r
# Creating a data frame only containing completed matchday IDs
IDs <- subset(Player_Info, select = 'Player ID')
IDs <- IDs %>% rename(id = `Player ID`)
````
2 - Creating an empty data frame that we will append all the nex data frames created for each player
````r
# Creating an empty data frames
Player_Gameweeks_data_frames <- list()
````
3 - Constructing the looping api call, during the loop I found that calling historic data for all players was not possible as there were some players that where new to the league as of the current season. These players would return no data and cause the loop to fail. Hence there was the need for error handelling. This can be seen below with the syntax: if (nrow(df) > 0) 
This now only appends a data frame if there is more than 0 rows of data, solving the problem.
Within the loop new data frames are being appended to the empty data frames created in step 1.
````r
for (id in IDs$id) {
  
  # Creates a url that changes the value id based on the loop
  url <- paste0("https://fantasy.premierleague.com/api/element-summary/",id,"//")
  
  # A GET call to the FPL API using the url constructed
  res = VERB("GET", url = url)
  
  # converts the response of the API call into text
  res2 <- content(res, "text", encoding = "UTF-8")
  
  # Converts the text response from JSON
  item <- fromJSON(res2)
  
  # Creating a data frame with the parsed JSON data
  df <- data.frame(item$history_past)
  
  # Error handling, Only proceeds if there is data for the player id
  if (nrow(df) > 0) {
    
    # creating a new column
    df[,"Player_ID"] <- id
    
    # Creates a new data frame with the game week data and labels it accordingly
    Player_Gameweeks_data_frames[[id]] <- df
    
    # Combining all the individual data frames created into one
    `Player_Historic_Stats` <- bind_rows(Player_Gameweeks_data_frames)
    
  }
}
````
### Web Scraping
Using the rvest package made it very easy to webscrape the premier league standings data. 
The first line of code is simply creating an object called html that includes the URL with the data. The next code creates a data frame title "Standings" from the table of data within the html retrieved from the download.
````r
# Webscraping the data from the URL provided
html <- read_html("https://www.bbc.co.uk/sport/football/premier-league/table")

# Creating a data frame from the data web scraped. In this case the html element is a table.
Standings <- data.frame(
  html %>% 
    html_element("table") %>% 
    html_table()
)
````

## Github Actions 🎬
### Github Actions
In order to have the r script run automatically on a schedule I decided to use Github Actions. A YAML file is needed to create workflows. 
- Firstly a virtual machine is started and installs R and all the packages needed for the R Script to run.
- Specifying "runs-on: ubunto-latest" means that the virtual machine is running linux. Linus is the cheapest opperating system to run actions on and is more than adequate for the purpose of running the r script.
- The YAML code then also states the schedule on which the workflow will run. The worfklow hence runs at 5:30 am everyday.
- "Steps: uses" specifies to set up r using the renv file in the repository
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
### FPL Dashboard
Coming soon to a screen near you...
