# FPL Data Pipeline Project
![](https://fantasy.premierleague.com/img/share/facebook-share.png)

**An FPL data project using R, Github Actions and Tableau**

## Project overview ⚽
Diagram of data pipeline

## API & Webscrapping 🛜
### API
It was chalolanging to find the documentation for the FPL API however i was able to find information through others that have already connect to it. 
My main source of information regarding the API was [https://www.game-change.co.uk/2023/02/10/a-complete-guide-to-the-fantasy-premier-league-fpl-api/#google_vignette.](https://www.oliverlooney.com/blogs/FPL-APIs-Explained)

Using the link a list of endpoints can be found with the data that is included in each endpoint. For the purpose of this project I did not use any endpoints that gave data regarding specific leagues or users teams.

The base URL is bootstrap-static/ and using the endpoints in the table returns you the fields stated in the table.
| End Point Used | Notes |
|---- |---- |
|element-summary/"{id}"//|used to retrieve data on players throughout the current and previous season.<br>Data for current season is at the matchday level, whilst data for historic seasons is aggregated to the season level.|
|bootstrap-static/|used to get an overview of teams and player info.|
|fixtures/|returns all the data regarding all completed and future matches.|

### Webscraping
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
### Example of API Call
### Example of looping through API Call
The endpoint used for retrieving the player stats is such that you can only call data from one player at a time using their player id. In order to download the data for all players possible it was neccessary to create a loop.
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
3 - Constructing the looping api call, during the loop I found that calling historic data for all players was not possible as there were some players that where new to the league as of the current season. These players would return no data and cause the loop to fail. Hence there was the need for error handelling. This can be seen on line 
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
### Webscraping example
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

## Github actions 🎬
In order to have the r script run automatically on a schedule I decided to use Github Actions. A YAML file is needed to create workflows. 

Firstly a virtual machine is started and installs R and all the packages needed for the R Script to run.
specifying "runs-on: ubunto-latest" means that the virtual machine is running linux. Linus is the cheapest opperating system to run actions on and is more than adequate for the purpose of running the r script. the YAML code then also states the schedule on which the workflow will run. The worfklow hence runs at 5:30 am everyday.
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
