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
It was a challenging to find the official documentation for the FPL API. However, I was able to find information through others that have already connect to it.

There are a variety of different endpoints available. The list of the endpoints I used are in the table below, however for a more extensive list of endpoints use the link [https://www.game-change.co.uk/2023/02/10/a-complete-guide-to-the-fantasy-premier-league-fpl-api/#google_vignette.](https://www.oliverlooney.com/blogs/FPL-APIs-Explained)

The base URL for the endpoints used in this project is https://fantasy.premierleague.com/api/bootstrap-static/
| End Point Used | Notes |
|---- |---- |
|element-summary/"{id}"//|Used to retrieve data on players throughout the current and previous season.<br>Data for current season is at the matchday level, whilst data for historic seasons is aggregated to the season level.|
|bootstrap-static/|Used to get an overview of teams and player info.|
|fixtures/|Returns all the data regarding all completed and future matches.|

### Web Scraping
I found that the API which returns data regarding the current league standings was not returning up to date information. Hence, I decided to retrieve the premier league standings table through webscraping.
After looking through a few options the website that gave the data in the kindest format was the bbc webiste (https://www.bbc.co.uk/sport/football/premier-league/table)

## R Script ®️
### R Packages
The table below shows the packages that were used for this project and a brief note on the purpose and use that each package had.
| R Package | Useage | Link |
|---- |---- |---- | 
| conflicted | Used to resolve conflicts from functions between packages |[Documentation](https://cran.r-project.org/web/packages/conflicted/conflicted.pdf)|
| httr | Used for making API Calls |[Documentation](https://cran.r-project.org/web/packages/httr/httr.pdf)|
| jsonlite | Converts json into R objects |[Documentation](https://cran.r-project.org/web/packages/jsonlite/jsonlite.pdf)|
| tidyverse | collection of packages that help with transforming data |[Documentation](https://cran.r-project.org/web/packages/tidyverse/tidyverse.pdf)|
| progress | Creates a progress bar. Improves user experience when building loops as gives an idea on how long code will take to run. |[Documentation](https://cran.r-project.org/web/packages/progress/progress.pdf)|
| rvest | Used for webscraping data |[Documentation](https://cran.r-project.org/web/packages/rvest/rvest.pdf)|
|googlesheets4|Authenticates google to be able to save files directly to google sheets|[Documentation](https://cran.r-project.org/web/packages/googlesheets4/googlesheets4.pdf)|
### API Call
The same structure of code was used for each API call. The steps below outline the logic of extracting and converting the API data into usable data frames

1 - Using the endpoint to make a "GET" API call. 
````r
res = VERB("GET", url = "https://fantasy.premierleague.com/api/fixtures/")
````

2 - Convert the reponse of the API call into json
````r
res2 <- content(res, "text", encoding = "UTF-8")
````

3 - Convert the response from JSON
````r
item <- fromJSON(res2)
````

4 - Create a data frame with the parsed JSON Data
````r
Fixtures <- data.frame(item)
````

### Looping API Call
The endpoint used for retrieving the player stats is such that you can only call data from one player at a time using the player id. In order to download the data for all players possible it was neccessary to create a loop that cycles through all possible player ids and downloads the respective data.<br>
<br>1 - Create a new data frame using the Player IDs table. The data frame is one column and includes all possible player ids
````r
# Creating a data frame only containing completed matchday IDs
IDs <- subset(Player_Info, select = 'Player ID')
IDs <- IDs %>% rename(id = `Player ID`)
````
2 - Creating an empty data frame that we will append all the individual data frames created for each player
````r
# Creating an empty data frames
Player_Gameweeks_data_frames <- list()
````
3 - Using the structure of code outlined above to extract and clean the API data. However, due to the looping I needed to add a step at the end that would combine the data frame for each individual player id to the overal data frame created in step 2.
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
#### Error Handeling
In constructing the loop I found that calling historical data for all players was not possible as there were some players that where new to the league as of the current season. These players would return no data and cause the loop to fail.<br>
The syntax: if (nrow(df) > 0) controls the errors as it will only append a data frame if there is more than 0 rows of data.

### Web Scraping
As explained above the need for web scraping was a result of the API Standings data not being reliable. In order to webscrape I wanted to find a site that would be a reliable source of data, Stable URL (I.e. not likely to change) and return the data in an easy format to manage. Given this set of criteria I decided that teh BBC website would be suitable (https://www.bbc.co.uk/sport/football/premier-league/table).

1 - Create an object called html that includes the URL with the data. Doing this means that if there is the need to change URL it can be done easily.
````r
# Webscraping the data from the URL provided
html <- read_html("https://www.bbc.co.uk/sport/football/premier-league/table")
````
2 - Creates a data frame title "Standings" from the table of data within the html retrieved from the download. Part of the reason why I decided to use the BBC website is because the html_element was a table and this made it easy to create the data frame. 
````r
# Creating a data frame from the data web scraped. In this case the html element is a table.
Standings <- data.frame(
  html %>% 
    html_element("table") %>% 
    html_table()
)
````

### Google Sheets
Once the R script extracts all the data required from the API and creates data frames I needed a way of saving the files prior to the virtual machine closing (See Github Actions for brief explanation on virtual machine). I chose to upload to google sheets primarily because it is possible to automate the refresh of data for a Tableau Public Dashboard only by using google sheets. 

In order to save to google sheets I needed to first have a way of authenticating to my google account using R. The following link provides a more detailed guide to (Authenticating google in R)[https://www.obrien.page/blog/2023/03_10_google_and_github_actions/]


## Github Actions 🎬
### Github Actions
Github actions work such that you are able to use a virtual machine, install the required software, run a progrem (in this case the R script) and then close the machine down. 

The logcic of how the data refresh can be automated is as follows:
1 - A YAML file is needed to create workflows. 
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
