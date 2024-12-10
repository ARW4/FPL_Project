# FPL Data Pipeline Project
![FPL Data Pipeline](https://github.com/user-attachments/assets/6dd9fa9a-6a2e-4528-bcd8-49ae29627c54)

## Project overview ⚽
The aim of this project was to create an end to end data pipeline solution. This idea was born out of working for a client that was thinking about how it could use Google Cloud Platform (GCP) to create a fully automated data pipeline. Prior to this project I had not extensively used GCP and hence this project was to better my understanding of its ability. I am pleased that I was able to create the Pipeline and have documented the process below. There are a few outcomes from this project:<br>
- A dashboard that you can view [here](https://public.tableau.com/app/profile/alexrwood/viz/FPLDashboard_17254712584930/FPL-Standings).
- I was able to continue developing on my ability using R and R Studio.
- I learnt how to use Github Actions, Secrets and Variables
- I was able to have a better understanding of how GCP can be used to help create a data pipeline.

I have learnt a lot from taking on this project and I hope that you enjoy reading about my process as much as I enjoyed tackling this project :) 

## Contents 📖
[API](#API)
<br>[Web Scraping](#Web-Scraping)
<br>[R Packages](#R-packages)
<br>[API Call (R Script)](#API-Call)
<br>[Looping API Call (R Script)](#Looping-API-Call)
<br>[Web Scraping (R Script)](#Web-Scraping)
<br>[Google Sheets](#Google-Sheets)
<br>[Github Actions](#Github-Actions)
<br>[Google Cloud Platform (GCP)](#GCP)
<br>[Tableau Dashboard](#FPL-Dashboard)
<br>[Refreshing Dashboard](#Refreshing-Dashboard)

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
I found that the API which returns data regarding the current league standings was not returning up to date information. Hence, I decided to retrieve the premier league standings table through web scraping.
After looking through a few options the website that gave the data in the kindest format was the bbc website (https://www.bbc.co.uk/sport/football/premier-league/table)

## R Script ®️
### R Packages
The table below shows the packages that were used for this project and a brief note on the purpose and use that each package had.
| R Package | Usage | Link |
|---- |---- |---- | 
| conflicted | Used to resolve conflicts from functions between packages |[Documentation](https://cran.r-project.org/web/packages/conflicted/conflicted.pdf)|
| httr | Used for making API Calls |[Documentation](https://cran.r-project.org/web/packages/httr/httr.pdf)|
| jsonlite | Converts Json into R objects |[Documentation](https://cran.r-project.org/web/packages/jsonlite/jsonlite.pdf)|
| tidyverse | collection of packages that help with transforming data |[Documentation](https://cran.r-project.org/web/packages/tidyverse/tidyverse.pdf)|
| progress | Creates a progress bar. Improves user experience when building loops as gives an idea on how long code will take to run. |[Documentation](https://cran.r-project.org/web/packages/progress/progress.pdf)|
| rvest | Used for web scraping data |[Documentation](https://cran.r-project.org/web/packages/rvest/rvest.pdf)|
|googlesheets4|Authenticates google to be able to save files directly to google sheets|[Documentation](https://cran.r-project.org/web/packages/googlesheets4/googlesheets4.pdf)|
### API Call
The same structure of code was used for each API call. The steps below outline the logic of extracting and converting the API data into usable data frames

1 - Using the endpoint to make a "GET" API call. 
````r
res = VERB("GET", url = "https://fantasy.premierleague.com/api/fixtures/")
````

2 - Convert the response of the API call into Json
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
The endpoint used for retrieving the player stats is such that you can only call data from one player at a time using the player id. In order to download the data for all players possible it was necessary to create a loop that cycles through all possible player ids and downloads the respective data.<br>
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
3 - Using the structure of code outlined above to extract and clean the API data. However, due to the looping I needed to add a step at the end that would combine the data frame for each individual player id to the overall data frame created in step 2.
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
#### Error Handling
In constructing the loop I found that calling historical data for all players was not possible as there were some players that were new to the league as of the current season. These players would return no data and cause the loop to fail.<br>
The syntax: if (nrow(df) > 0) controls the errors as it will only append a data frame if there is more than 0 rows of data.

### Web Scraping
As explained above the need for web scraping was a result of the API Standings data not being reliable. In order to web scrape I wanted to find a site that would be a reliable source of data, Stable URL (I.e. not likely to change) and return the data in an easy format to manage. Given this set of criteria I decided that the BBC website would be suitable (https://www.bbc.co.uk/sport/football/premier-league/table).

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

## Github Actions 🎬
### Github Actions
Github actions work such that you are able to use a virtual machine, install the required software, run a program (in this case the R script) and then close the machine down. 

To run the github action I wrote the YAML script which can be found in the .github/workflows folder of this repository. The following is an explanation of the steps within the YAML script
<br> Creating the schedule:
- Creating the title for the action called "schedule"
- Determining that the action run on a schedule at 5:30 every morning
````yaml
name: schedule

on:
  schedule:
  - cron : "30 5 * * *"
````
<br> Creating the job:
 - running the action on ubuntu-latest means that it will run on the latest version of linux
 - specifying to download R to run on the virtual machine followed by setting up the R environment using the renv.lock file in the repository. Loading in the environment means that all the packages needed for the R script are already installed.
````yaml
jobs:
  import-data:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: r-lib/actions/setup-r@v2
      - uses: r-lib/actions/setup-renv@v2
````
<br> Running the script:
- loading in the private key that is saved in the repository (see [Authenticating Google Sheets](#R-Code) for use in R code)
- Run the R script that is in the repository
````yaml
      - name: FPL Code
        env: 
          PRIVATE_KEY: ${{ secrets.PRIVATE_KEY }}
          GOOGLE_SHEETS_URL: ${{ vars.GOOGLE_SHEETS_URL }}
        run : 
          Rscript -e 'source("FPL_API.R")'
````
<br> Saving the output & closing virtual machine:
- The r script creates csv files that need to be saved back to the repository before the virtual machine uninstalls and closes.
- Github actions does this by committing the results using the local email and username
- The YAML code specifies to only update the files in the repository if there are changes to commit. If there are no updates to the data then the results will not be committed. 
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

## Google Cloud Platform ☁️
### GCP
### Using Github actions and R to Authenticating Google Sheets using a service account
Using github actions means that I was able to automate the running of my script on a pre determined schedule. This was essential as I wanted the data pipeline to be fully automated. After automating the running of the script I then needed a way of saving the tables created somewhere that I could use for a Tableau dashboard. Tableau Public allows for data to refresh only when using the google sheets connector, hence the reason why I decided to save the data to google sheets. <br>

- Create a new project in GCP or select an existing one you would like to use
- Create Credentials:
  - Create Credentials > API Key
  - Create credentials > Service Account (This step will download the service account credentials in JSON format)
- Using the menu in the top left of the GCP console navigate to APIs & Services > Enable APIs & Services. Here you need to enable the following APIs
  - Google Sheets API
  - Google Drive API
  - IAM Servcie Account Credentials API
  - Identity and Access Management (IAM)API

### Using the Credentials saved as JSON you can now past this into github secrets.
- Navigate to your Repository > Settings > Secrets and variables > Actions > New repository secret
- Name your secret appropriately and this is the name that you will substitute into the YAMl code above. In my repository the secret is called PRIVATE_KEY, this is reflected in the YAML code as secrets.PRIVATE_KEY

### Saving Google Sheets URL as Repository variable
- Navigate to your Repository > Settings > Secrets and variables > Actions > Variables > New repository variable
- Name your variable appropriately and this is the name that you will substitute into the YAMl code above. In my repository the variable is called GOOGLE_SHEETS_URL, this is reflected in the YAML code as vars.GOOGLE_SHEETS_URL

### R Code
Everything in GCP and Github is set up to be able to run a script that authenticates google and saves data frames to google sheets.
What authenticating looks like in terms of R code is rather simple:
  - You need to call in the credentials.
  - you can then use the googlesheets4 package to authenticate (gs4_auth())

````r
# Calling in credentials through github secrets.
json_string <- Sys.getenv("PRIVATE_KEY")

# Authenticating google
gs4_auth(path = json_string)
````
<br>
For more detail into authenticating google sheets in github actions using R use the following link: https://www.obrien.page/blog/2023/03_10_google_and_github_actions/
<br> 
<br> Given google has authenticated, to save to google sheets use the following steps:

1 - Calling in the Google Sheets URL from a repository variable 
````r
Google_Sheets_Url <- Sys.getenv("GOOGLE_SHEETS_URL")
  ````

<br> 2 - Clear the data in the sheets
````r

range_clear(Google_Sheets_Url,
            sheet = "Standings",
            range = NULL
)
````

3 - Writing the new data into the sheet
````r
write_sheet(Standings, 
            Google_Sheets_Url,
            sheet = "Standings"
)
````
## Tableau Dashboard 📊
### FPL Dashboard
 [Link to the dashboard on Tableau Public](https://public.tableau.com/app/profile/alexrwood/viz/FPLDashboard_17254712584930/FPL-Standings)
 <br>

![FPL - Standings](https://github.com/user-attachments/assets/b837cfb3-25c5-4f44-ac37-6c1f059c20ec)
![FPL - Club Detail](https://github.com/user-attachments/assets/02d83c62-e014-43ea-beb6-f457f3fb4ead)
![FPL - Player Detail](https://github.com/user-attachments/assets/2f7018c7-a109-4461-8ade-d793074238da)
![FPL - Hidden Gems](https://github.com/user-attachments/assets/11c71e2f-0711-4cf0-8878-fcdff2067958)

## Refreshing Dashboard
I wanted to make sure that the refreshing of the data in the dashboard was done automatically. I explored a few options for this, I decided on using python and Selenium to create a bot that would log into my tableau public account and click on the refresh data option. The main reason for me choosing this method was that I knew it would work and I really wanted to practice using python and Selenium.
<br> The python code that makes the data refresh possible can be found [here](https://github.com/ARW4/FPL_Project/blob/main/Dashboard_Refresh.py). 

The section of code below is needed to create the google chrome driver
````python
# Ensure that the driver .exe file is saved in the some directory as the code
#service = Service(executable_path="chromedriver.exe")
#driver = webdriver.Chrome(service=service)
chrome_options = Options()
chrome_options.add_argument('--no-sandbox')
chrome_options.add_argument('--headless')
chrome_options.add_argument('--disable-dev-shm-usage')
driver_path = Service(ChromeDriverManager(chrome_type=ChromeType.CHROMIUM).install())
driver = webdriver.Chrome(service=driver_path, options=chrome_options)
````

One of the things I found through building the code was that if the browser was minimized or maximised the element I needed the bot to click on would be different. Hence I added a step to maximise the window.
````python
driver.maximize_window()
````

After maximising the window I needed to navigate to the Tableau Public website
````python
# URL to navigate to
website = "https://public.tableau.com/app/profile/alexrwood/viz/FPLDashboard_17254712584930/FPL-Standings"
driver.get(website)
````

Next I need to click the signin button to be able to input my Email and Password. I began by trying to use element ID to dictate which web welement to select however I found that using XPATH was more consistent.
````python
# Click on Sign in button
wait.until(
    EC.element_to_be_clickable(
        (
            By.XPATH,
            "//*[@id='root']/div/header/div/div[2]/div/button",
        )
    )
).click()
````

In order to input my Email and Password into the python code I used Github secrets/variables so that users wouldn't be able to see them. 
````python
# Type in email
input_element = driver.find_element(By.XPATH, "//*[@id='email']")
environ_email = os.environ["TABLEAU_EMAIL"]
input_element.send_keys (environ_email)

# Type in password
input_element = driver.find_element(By.XPATH, "//*[@id='password']")
environ_password = os.environ["TABLEAU_PASSWORD"]
input_element.send_keys (environ_password)
````
