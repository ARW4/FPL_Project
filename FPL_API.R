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

# Printing stage complete
message("Dependencies Complete")

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

# Printing stage complete
message("Team Info Complete")

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

# Creating the position column
Standings$Position <- as.numeric(str_extract_all(Standings$Team, "[0-9]+"))

# Removing the letters at the start of the Team Column
Standings$Team <- gsub("\\d","",Standings$Team)

# Joining tables based on team names
Standings <- left_join(Standings, Teams, join_by( Team == Team))

# Keeping only relevent fields
#Standings <- subset(Standings, select = c(Position, Team, Abbreviation, `Team Strength`, Played, Won, Drawn, Lost, Goals.For, Goals.Against, Goal.Difference, Points, `Team ID`))

# Renaming Columns
Standings <- Standings %>% rename(`Goals For` = Goals.For,
                                  `Goals Against` = Goals.Against,
                                  `Goal Difference` = Goal.Difference
)

# Printing stage complete
message("Standings Complete")

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

# Printing stage complete
message("Fixtures Complete")

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

# Printing stage complete
message("Player Info Complete")

#---------- Player_Gameweek_Stats (df) ----------
# Creating a data frame only containing completed matchday IDs
IDs <- subset(Player, select = 'Player ID')
IDs <- IDs %>% rename(id = `Player ID`)

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

  #Error handeling, Only proceeds if there is data for the player id
  if (nrow(df) > 0) {
  
    # creating a new column
    df[,"Player_ID"] <- id
  
    # Creates a new data frame with the gameweek data and labels it accordingly
    Player_Gameweeks_data_frames[[id]] <- df
  
    # Combining all the individual data frames created into one
    `Gameweek` <- bind_rows(Player_Gameweeks_data_frames)
  }
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

# Printing stage complete
message("Player Gameweek Complete")

#---------- Player_Historic_Stats (df) ----------

# Creating a data frame only containing completed matchday IDs
IDs <- subset(Player, select = 'Player ID')
IDs <- IDs %>% rename(id = `Player ID`)

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

# Printing stage complete
message("Player Historic Gameweek Complete")

#---------- Creating CSV files ----------
write.csv(Fixtures, "Fixtures.csv", row.names =  FALSE)
write.csv(Gameweek, "Gameweek.csv", row.names =  FALSE)
write.csv(Historic_Seasons, "Historic_Seasons.csv", row.names =  FALSE)
write.csv(Player, "Player.csv", row.names =  FALSE)
write.csv(Standings, "Standings.csv", row.names =  FALSE)

# Printing stage complete
message("Creating CSV Files Complete")

#---------- Autheticating Google Sheets ----------
# Calling in credentials through github secrest.
json_string <- Sys.getenv("PRIVATE_KEY")

# Authenticating google
gs4_auth(path = json_string)

# Printing stage complete
message("Authenticating Google Sheets Complete")

#----------- Uploading to googlesheets ----------

# Calling in the Google Sheets url as a repository variable
Google_Sheets_Url <- Sys.getenv("GOOGLE_SHEETS_URL")

# Standings table
range_clear(Google_Sheets_Url,
            sheet = "Standings",
            range = NULL
)

write_sheet(Standings, 
            Google_Sheets_Url,
            sheet = "Standings"
)

#Fixtures table
range_clear(Google_Sheets_Url,
            sheet = "Fixtures",
            range = NULL
)

write_sheet(Fixtures, 
            Google_Sheets_Url,
            sheet = "Fixtures"
)

# Player table
range_clear(Google_Sheets_Url,
            sheet = "Player",
            range = NULL
)

write_sheet(Player, 
            Google_Sheets_Url,
            sheet = "Player"
)

#Gameweek table
range_clear(Google_Sheets_Url,
            sheet = "Gameweek",
            range = NULL
)

write_sheet(Gameweek, 
            Google_Sheets_Url,
            sheet = "Gameweek"
)

# Historic Seasons table
range_clear(Google_Sheets_Url,
            sheet = "Historic Seasons",
            range = NULL
)

write_sheet(`Historic_Seasons`, 
            Google_Sheets_Url,
            sheet = "Historic Seasons"
)

# Printing stage complete
message("Saving To Google Sheets Complete")
#---------- End of Script ----------

# Printing stage complete
message("END OF SCRIPT :)")
