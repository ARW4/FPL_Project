#--------- Clearing Environment & Console ---------
rm(list = ls())
cat("\014")

#---------- Downloading/Loading Packages ----------
#install.packages(c("httr","jsonlite","tidyverse","rvest","conflicted","progress"))
library(conflicted)
library(httr)
library(jsonlite)
conflict_prefer("filter","dplyr")
conflict_prefer("lag","dplyr")
library(tidyverse)
library(progress)
library(rvest)
library(googlesheets4)

#---------- Team Info ----------
# A GET call to the FPL API
res = VERB("GET", url = "https://fantasy.premierleague.com/api/bootstrap-static/")

# converts the response of the API call into text
res2 <- content(res, "text", encoding = "UTF-8")

# Converts the text response from JSON
item <- fromJSON(res2)

# Creating a data frame with the parsed JSON data
Teams <- data.frame(item$teams)

# Selecting which fields to keep
Teams <- subset(Teams, select = c(id, name, short_name, strength))

# Renaming fields
Teams <- Teams %>% rename (`Team ID` = id,
                           Team = name,
                           Abbreviation = short_name,
                           `Team Strength` = strength)

# Renames the values within the fields so that they can be mapped to other tables later on
Teams <- Teams %>% mutate(Team = case_when(
  Team == "Arsenal" ~ "Arsenal",
  Team == "Aston Villa" ~ "Aston Villa",
  Team == "Bournemouth" ~ "AFC Bournemouth",
  Team == "Brentford" ~ "Brentford",
  Team == "Brighton" ~ "Brighton & Hove Albion",
  Team == "Chelsea" ~ "Chelsea",
  Team == "Crystal Palace" ~ "Crystal Palace",
  Team == "Everton" ~ "Everton",
  Team == "Fulham" ~ "Fulham",
  Team == "Ipswich" ~ "Ipswich Town",
  Team == "Leicester" ~ "Leicester City",
  Team == "Liverpool" ~ "Liverpool",
  Team == "Man City" ~ "Manchester City",
  Team == "Man Utd" ~ "Manchester United",
  Team == "Newcastle" ~ "Newcastle United",
  Team == "Nott'm Forest" ~ "Nottingham Forest",
  Team == "Southampton" ~ "Southampton",
  Team == "Spurs" ~ "Tottenham Hotspur",
  Team == "West Ham" ~ "West Ham United",
  Team == "Wolves" ~ "Wolverhampton Wanderers"
))

# Removing objects from environment
rm(item,res,res2)

#---------- Standings (df) ---------
# Webscraping the data from the URL provided
html <- read_html("https://www.bbc.co.uk/sport/football/premier-league/table")

# Creating a data frame from the data web scraped. In this case the html element is a table.
Standings <- data.frame(
  html %>% 
    html_element("table") %>% 
    html_table()
)

# Removing obejects from environment
rm(html)

# Joining tables based on team names
Standings <- left_join(Standings, Teams, join_by( Team == Team))

# Keeping only relevent fields
Standings <- subset(Standings, select = c(Position, Team, Abbreviation, `Team Strength`, Played, Won, Drawn, Lost, Goals.For, Goals.Against, Goal.Difference, Points, `Team ID`))

# Renaming Columns
Standings <- Standings %>% rename(`Goals For` = Goals.For,
                                  `Goals Against` = Goals.Against,
                                  `Goal Difference` = Goal.Difference
)


#---------- Fixtures (df) ----------

# A GET call to the FPL API
res = VERB("GET", url = "https://fantasy.premierleague.com/api/fixtures/")

# converts the response of the API call into text
res2 <- content(res, "text", encoding = "UTF-8")

# Converts the text response from JSON
item <- fromJSON(res2)

# Creating a data frame with the parsed JSON data
Fixtures <- data.frame(item)

# Removing objects from environment
rm(res, res2, item)

# Joining tables so that instead of TEAM ID's we have the actual team names
Fixtures <- left_join(Fixtures,Teams, join_by(team_a == `Team ID`))

Fixtures <- Fixtures %>% rename(`Away Team` = Team)

Fixtures <- left_join(Fixtures,Teams, join_by(team_h == `Team ID`))

Fixtures <- Fixtures %>% rename(`Home Team` = Team)

# Keeping only relevent fields
Fixtures <- subset(Fixtures, select = c(id, event,finished, kickoff_time,`Home Team` , `Away Team`, team_h_score, team_a_score, team_h_difficulty, team_a_difficulty))

# Renaming fields
Fixtures <- Fixtures %>% rename (Matchday = event,
                                 Finished = finished,
                                 `Match ID` = id,
                                 `Kick-off Time` = kickoff_time,
                                 `Away Team Score` = team_a_score,
                                 `Home Team Score` = team_h_score,
                                 `Difficulty For Home Team` = team_h_difficulty,
                                 `Difficulty For Away Team` = team_a_difficulty)

# Extracting only the date from the Kick-off Time field
Fixtures$`Kick-off Time` = substr(Fixtures$`Kick-off Time`,1,10)

# Pivotting the Fixtures Table so that each row is unique by the combination of Match ID and Team
Fixtures <- Fixtures %>% 
  pivot_longer(cols = c(`Home Team`, `Away Team`), 
               names_to = "Team_Type", 
               values_to = "Team")

# Joining the fixtures table to itself so that we can get the oppositon team for each row.
# There is also renaming of fields and removing columns that happenes after the join
Fixtures <- inner_join(Fixtures,Fixtures, join_by( `Match ID` == `Match ID`),relationship = "many-to-many") %>%
  filter(Team.x != Team.y) %>%
  rename(Opponent = Team.y,
         Team = Team.x,
         `Home or Away` = Team_Type.x,
         Matchday = Matchday.x,
         Finished = Finished.x,
         `Kick-off Time` = `Kick-off Time.x`,
         `Home Team Score` = `Home Team Score.x`,
         `Away Team Score` = `Away Team Score.x`,
         `Difficulty For Home Team` = `Difficulty For Home Team.x`,
         `Difficulty For Away Team` = `Difficulty For Away Team.x`)%>%
  select(-Matchday.y, -Team_Type.y, -Finished.y, -`Difficulty For Home Team.y`,-`Difficulty For Away Team.y`,-`Home Team Score.y`,-`Away Team Score.y`,-`Kick-off Time.y`)

# Cleaning the column of Home or Away
Fixtures$`Home or Away` <- str_remove_all(Fixtures$`Home or Away`," Team")

df <- subset(Teams, select = c(`Team ID`, Team))

Fixtures <- inner_join(Fixtures, df, join_by(Team == Team))

rm(df, Teams)

#---------- Player_Info (df) ----------

# A GET call to the FPL API
res = VERB("GET", url = "https://fantasy.premierleague.com/api/bootstrap-static/")

# converts the response of the API call into text
res2 <- content(res, "text", encoding = "UTF-8")

# Converts the text response from JSON
item <- fromJSON(res2)

# Creating a data frame with the parsed JSON data
Player <- data.frame(item$elements)

# Removing objects from the environment
rm(res, res2, item)

# Keeping only relevent fields
Player <- subset(Player, select = c(id, first_name, second_name, element_type, team,  now_cost, form, photo, selected_by_percent,
                                    chance_of_playing_next_round,chance_of_playing_this_round, dreamteam_count, in_dreamteam, news, news_added, 
                                    corners_and_indirect_freekicks_order, direct_freekicks_order, penalties_order)
)

# Renaming fields
Player <- Player %>% rename(`Player ID` = id, `First Name` = first_name, `Second Name` = second_name, Position = element_type, `Selected %` = selected_by_percent,`Team ID` = team,
                            `Current Cost` = now_cost, Form = form, Photo = photo, `Chance of playing next round` = chance_of_playing_next_round,
                            `Chance of playing this round` = chance_of_playing_this_round, `Dreamteam Count` = dreamteam_count, `In Dreamteam` = in_dreamteam,
                            News = news, `News Added` = news_added, `Corners & Indirect freekicks order` = corners_and_indirect_freekicks_order,
                            `Direct freekicks order` = direct_freekicks_order,`Penalties Order` = penalties_order)

# A GET call to the FPL API
res = VERB("GET", url = "https://fantasy.premierleague.com/api/bootstrap-static/")

# converts the response of the API call into text
res2 <- content(res, "text", encoding = "UTF-8")

# Converts the text response from JSON
item <- fromJSON(res2)

# Creating a data frame with the parsed JSON data
Element <- data.frame(item$element_types) %>%
  select(id , singular_name)

Player <- inner_join(Player, Element, join_by( Position == id)) %>%
  select(-Position)

Player <- Player %>% rename(Position = singular_name)#

rm(Element)


#---------- Player_Gameweek_Stats (df) ----------
# Creating a data frame only containing completed matchday IDs
IDs <- subset(Player, select = 'Player ID')
IDs <- IDs %>% rename(id = `Player ID`)
IDs <- head(IDs)

# Creating an empty data frames
Player_Gameweeks_data_frames <- list()

pb_1 <- progress_bar$new(total = nrow(IDs))

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
  df <- data.frame(item$history)
  
  # creating a new column
  df[,"Player_ID"] <- id
  
  # Creates a new data frame with the gameweek data and labels it accordingly
  Player_Gameweeks_data_frames[[id]] <- df
  
  # Combining all the individual data frames created into one
  `Gameweek` <- bind_rows(Player_Gameweeks_data_frames)
  
  pb_1$tick()
}

# Removing objects from the environment
rm(df,IDs,item,pb_1,Player_Gameweeks_data_frames,res,id,res2,url)

# Renaming fields
Gameweek <- Gameweek %>% rename(Fixture = fixture, `Opponent Team` = opponent_team, `Total Points` = total_points,
                                Gameweek = round, Minutes = minutes, `Goals Scored` = goals_scored, Assists = assists,
                                `Clean Sheets` = clean_sheets, `Goals Conceded` = goals_conceded, `Own goals` = own_goals,
                                `Penalties Saved` = penalties_saved,`Penalties Missed` = penalties_missed, `Yellow Cards` = yellow_cards,
                                `Red Cards` = red_cards, Saves = saves, Bonus = bonus, Influence = influence, Creativity = creativity,
                                Threat = threat, `ICT Threat` = ict_index, Starts = starts, xG = expected_goals, xA = expected_assists,
                                `xG Involvements` = expected_goal_involvements, `xG Conceded` = expected_goals_conceded, Value = value,
                                `Transfer Balance` = transfers_balance, Selected = selected, `Transfers In` = transfers_in,
                                `Transfers Out` = transfers_out, `Player ID` = Player_ID, `Kick-off Time` = kickoff_time)

Gameweek <- subset(Gameweek, select = -c(was_home, team_h_score, team_a_score, element, Fixture))


#---------- Player_Historic_Stats (df) ----------

# Creating a data frame only containing completed matchday IDs
IDs <- subset(Player, select = 'Player ID')
IDs <- IDs %>% rename(id = `Player ID`)
IDs <- head(IDs)

# Creating an empty data frames
Player_Gameweeks_data_frames <- list()

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
    Historic_Seasons <- bind_rows(Player_Gameweeks_data_frames)
    
  }
}

# Removing objects from the environment
rm(df,IDs,item,Player_Gameweeks_data_frames,res,id,res2,url)

# Renaming fields
Historic_Seasons <- Historic_Seasons %>% rename(Season = season_name, `Start Cost` = start_cost, `End Cost` = end_cost, `Total Points` = total_points,
                                                Minutes = minutes, `Goals Scored` = goals_scored, Assists = assists, `Clean Sheets` = clean_sheets, 
                                                `Goals Conceded` = goals_conceded, `Own Goals` = own_goals, `Penalties Saved` = penalties_saved, `Yellow cards` = yellow_cards,
                                                `Red Cards` = red_cards, Saves = saves, `Bonus Points` = bonus, Influence = influence, Creativity = creativity, Threat = threat,
                                                `ICT Index` = ict_index, Starts = starts, xG = expected_goals, xA = expected_assists, `xG Involvements` = expected_goal_involvements,
                                                `xG Conceded` = expected_goals_conceded, `Player ID` = Player_ID)

# Removing fields
Historic_Seasons <- subset(Historic_Seasons, select = -c(element_code))

#---------- Creating CSV files ----------
write.csv(Fixtures, "Fixtures.csv", row.names =  FALSE)
write.csv(Gameweek, "Gameweek.csv", row.names =  FALSE)
write.csv(Historic_Seasons, "Historic_Seasons.csv", row.names =  FALSE)
write.csv(Player, "Player.csv", row.names =  FALSE)
write.csv(Standings, "Standings.csv", row.names =  FALSE)

#---------- Autheticating Google Sheets ----------
# Calling in private key through environment variable and formatting JSON string
env_private_key <- Sys.getenv("PRIVATE_KEY")
#env_private_key <- gsub("\\\\", "*",Key)
#env_private_key <- gsub("\\*n","\n",env_private_key)

# Creating values needed for JSON String
type <- "service_account"
project_id <- "fpl-api-433015"
private_key_id <- "fca98a1709675f36bc44239c90c1a35fdbc2d904"
client_email <- "gsheets-connection@fpl-api-433015.iam.gserviceaccount.com"
client_id <- "108907979042551286206"
auth_uri <- "https://accounts.google.com/o/oauth2/auth"
token_uri <-  "https://oauth2.googleapis.com/token"
auth_provider_x509_cert_url <- "https://www.googleapis.com/oauth2/v1/certs"
client_x509_cert_url <- "https://www.googleapis.com/robot/v1/metadata/x509/gsheets-connection%40fpl-api-433015.iam.gserviceaccount.com"
universe_domain <- "googleapis.com"

# Creating JSON string from the values created above
json_string = list(type = "service_account",
                   project_id = "fpl-api-433015",
                   private_key_id = "fca98a1709675f36bc44239c90c1a35fdbc2d904",
                   private_key = env_private_key,
                   client_email = "gsheets-connection@fpl-api-433015.iam.gserviceaccount.com",
                   client_id = "108907979042551286206",
                   auth_uri = "https://accounts.google.com/o/oauth2/auth",
                   token_uri =  "https://oauth2.googleapis.com/token",
                   auth_provider_x509_cert_url = "https://www.googleapis.com/oauth2/v1/certs",
                   client_x509_cert_url = "https://www.googleapis.com/robot/v1/metadata/x509/gsheets-connection%40fpl-api-433015.iam.gserviceaccount.com",
                   universe_domain = "googleapis.com"
)

# Removing objects
rm(auth_provider_x509_cert_url,auth_uri,client_email,client_id,client_x509_cert_url,env_private_key,private_key_id,project_id,token_uri,type,universe_domain)

# Converting the list of values into JSON, Preety and Auto_unbox - TRUE to match format needed
json_string <- toJSON(json_string, pretty = TRUE ,auto_unbox = TRUE)

# Authenticating google service account using JSON string
# gs4_auth(path = json_string)


gs4_auth(path = json_string)

#----------- Uploading to googlesheets ----------

# Standings table
range_clear("https://docs.google.com/spreadsheets/d/1k4H0SsvqbTOAaFBflMGQ-tie-12nODJJoDEJf-eQ6Vc/edit?gid=339894661#gid=339894661",
            sheet = "Standings",
            range = NULL
)

write_sheet(Standings, 
            "https://docs.google.com/spreadsheets/d/1k4H0SsvqbTOAaFBflMGQ-tie-12nODJJoDEJf-eQ6Vc/edit?gid=339894661#gid=339894661",
            sheet = "Standings"
)

#Fixtures table
range_clear("https://docs.google.com/spreadsheets/d/1k4H0SsvqbTOAaFBflMGQ-tie-12nODJJoDEJf-eQ6Vc/edit?gid=339894661#gid=339894661",
            sheet = "Fixtures",
            range = NULL
)

write_sheet(Fixtures, 
            "https://docs.google.com/spreadsheets/d/1k4H0SsvqbTOAaFBflMGQ-tie-12nODJJoDEJf-eQ6Vc/edit?gid=339894661#gid=339894661",
            sheet = "Fixtures"
)

# Player table
range_clear("https://docs.google.com/spreadsheets/d/1k4H0SsvqbTOAaFBflMGQ-tie-12nODJJoDEJf-eQ6Vc/edit?gid=339894661#gid=339894661",
            sheet = "Player",
            range = NULL
)

write_sheet(Player, 
            "https://docs.google.com/spreadsheets/d/1k4H0SsvqbTOAaFBflMGQ-tie-12nODJJoDEJf-eQ6Vc/edit?gid=339894661#gid=339894661",
            sheet = "Player"
)

#Gameweek table
range_clear("https://docs.google.com/spreadsheets/d/1k4H0SsvqbTOAaFBflMGQ-tie-12nODJJoDEJf-eQ6Vc/edit?gid=339894661#gid=339894661",
            sheet = "Gameweek",
            range = NULL
)

write_sheet(Gameweek, 
            "https://docs.google.com/spreadsheets/d/1k4H0SsvqbTOAaFBflMGQ-tie-12nODJJoDEJf-eQ6Vc/edit?gid=339894661#gid=339894661",
            sheet = "Gameweek"
)

# Historic Seasons table
range_clear("https://docs.google.com/spreadsheets/d/1k4H0SsvqbTOAaFBflMGQ-tie-12nODJJoDEJf-eQ6Vc/edit?gid=339894661#gid=339894661",
            sheet = "Historic Seasons",
            range = NULL
)

write_sheet(`Historic_Seasons`, 
            "https://docs.google.com/spreadsheets/d/1k4H0SsvqbTOAaFBflMGQ-tie-12nODJJoDEJf-eQ6Vc/edit?gid=339894661#gid=339894661",
            sheet = "Historic Seasons"
)

#---------- End of Script ----------
