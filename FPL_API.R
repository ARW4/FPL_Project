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

#---------- Team Info ----------

# A GET call to the FPL API
res = VERB("GET", url = "https://fantasy.premierleague.com/api/bootstrap-static/")

# converts the response of the API call into text
res2 <- content(res, "text", encoding = "UTF-8")

# Converts the text response from JSON
item <- fromJSON(res2)

# Creating a data frame with the parsed JSON data
Teams <- data.frame(item$teams)

# Removing objects from environment
rm(res, res2, item)

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
                                 `Away team Score` = team_a_score,
                                 `Home Team Score` = team_h_score,
                                 `Difficulty For Home Team` = team_h_difficulty,
                                 `Difficulty For Away Team` = team_a_difficulty)

# Extracting only the date from the Kick-off Time field
Fixtures$`Kick-off Time` = substr(Fixtures$`Kick-off Time`,1,10)

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
Standings <- subset(Standings, select = c(Position, Team, Abbreviation, `Team Strength`, Played, Won, Drawn, Lost, Goals.For, Goals.Against, Goal.Difference, Points))

# Renaming Columns
Standings <- Standings %>% rename(`Goals For` = Goals.For,
                                  `Goals Against` = Goals.Against,
                                  `Goal Difference` = Goal.Difference
                                  )

rm(Teams)

#---------- Player_Info (df) ----------

# A GET call to the FPL API
res = VERB("GET", url = "https://fantasy.premierleague.com/api/bootstrap-static/")

# converts the response of the API call into text
res2 <- content(res, "text", encoding = "UTF-8")

# Converts the text response from JSON
item <- fromJSON(res2)

# Creating a data frame with the parsed JSON data
Player_Info <- data.frame(item$elements)

# Removing objects from the environment
rm(res, res2, item)

# Keeping only relevent fields
Player_Info <- subset(Player_Info, select = c(id, web_name, element_type, team,  now_cost, total_points, form, photo, 
                                                  chance_of_playing_next_round,chance_of_playing_this_round, dreamteam_count, in_dreamteam, news, news_added, 
                                                  selected_by_percent,transfers_in, transfers_in_event, transfers_out, transfers_out_event, minutes,
                                                  goals_scored, assists, clean_sheets, goals_conceded, own_goals, penalties_saved, penalties_missed, yellow_cards,
                                                  red_cards, saves, bonus, starts, expected_goals, expected_assists, expected_goal_involvements, expected_goals_conceded,
                                                  corners_and_indirect_freekicks_order, direct_freekicks_order, penalties_order)
                                                  )

# Renaming fields
Player_Info <- Player_Info %>% rename(`Player ID` = id, Name = web_name, Position = element_type, Team = team, `Current Cost` = now_cost, `Total Points` = total_points,
                                          Form = form, Photo = photo, `Chance of playing next round` = chance_of_playing_next_round, 
                                          `Chance of playing this round` = chance_of_playing_this_round, `Dreamteam Count` = dreamteam_count,
                                          `In Dreamteam` = in_dreamteam, News = news, `News Added` = news_added, `Selected By Percent` = selected_by_percent, 
                                          `Total Transfers In` = transfers_in, `Gameweek transfers in` = transfers_in_event, `Total Transfers Out` = transfers_out,
                                          `Gameweek transfers out` = transfers_out_event, `Total minutes played` = minutes, `Goals Scored`= goals_scored,
                                          Assists = assists, `Clean Sheets` = clean_sheets, `Goals Conceded` = goals_conceded, `Own Goals` = own_goals,
                                          `Penalties Saved` = penalties_saved, `Penalties Missed` = penalties_missed, `Yellow Cards` = yellow_cards,
                                          `Red Cards` = red_cards, Saves = saves, `Total bonus points` = bonus, xG = expected_goals, xAssists = expected_assists,
                                          `xG Involvements` = expected_goal_involvements, `xG Conceded` = expected_goals_conceded, 
                                          `Corners & Indirect freekicks order` = corners_and_indirect_freekicks_order, `Direct freekicks order` = direct_freekicks_order,
                                          `Penalties Order` = penalties_order)

#---------- Player_Gameweek_Stats (df) ----------

# Creating a data frame only containing completed matchday IDs
IDs <- subset(Player_Info, select = 'Player ID')
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
  
  # creating a new column
  df[,"Player_ID"] <- id
  
  # Creates a new data frame with the gameweek data and labels it accordingly
  Player_Gameweeks_data_frames[[id]] <- df
  
  # Combining all the individual data frames created into one
  `Player_Gameweek_Stats` <- bind_rows(Player_Gameweeks_data_frames)
  
  pb_1$tick()
}

# Removing objects from the environment
rm(df,IDs,item,pb_1,Player_Gameweeks_data_frames,res,id,res2,url)

# Renaming fields
Player_Gameweek_Stats <- Player_Gameweek_Stats %>% rename(Fixture = fixture, `Opponent Team` = opponent_team, `Total Points` = total_points,
                                                          Gameweek = round, Minutes = minutes, `Goals Scored` = goals_scored, Assists = assists,
                                                          `Clean Sheets` = clean_sheets, `Goals Conceded` = goals_conceded, `Own goals` = own_goals,
                                                          `Penalties Saved` = penalties_saved,`Penalties Missed` = penalties_missed, `Yellow Cards` = yellow_cards,
                                                          `Red Cards` = red_cards, Saves = saves, Bonus = bonus, Influence = influence, Creativity = creativity,
                                                          Threat = threat, `ICT Threat` = ict_index, Starts = starts, xG = expected_goals, xA = expected_assists,
                                                          `xG Involvements` = expected_goal_involvements, `xG Conceded` = expected_goals_conceded, Value = value,
                                                          `Transfer Balance` = transfers_balance, Selected = selected, `Transfers In` = transfers_in,
                                                          `Transfers Out` = transfers_out, `Player ID` = Player_ID)

Player_Gameweek_Stats <- subset(Player_Gameweek_Stats, select = -c(was_home, team_h_score, team_a_score))

#---------- Player_Historic_Stats (df) ----------

# Creating a data frame only containing completed matchday IDs
IDs <- subset(Player_Info, select = 'Player ID')
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
  `Player_Historic_Stats` <- bind_rows(Player_Gameweeks_data_frames)
  
  }
}

# Removing objects from the environment
rm(df,IDs,item,Player_Gameweeks_data_frames,res,id,res2,url)

# Renaming fields
Player_Historic_Stats <- Player_Historic_Stats %>% rename(Season = season_name, `Start Cost` = start_cost, `End Cost` = end_cost, `Total Points` = total_points,
                                      Minutes = minutes, `Goals Scored` = goals_scored, Assists = assists, `Clean Sheets` = clean_sheets, 
                                      `Goals Conceded` = goals_conceded, `Own Goals` = own_goals, `Penalties Saved` = penalties_saved, `Yellow cards` = yellow_cards,
                                      `Red Cards` = red_cards, Saves = saves, `Bonus Points` = bonus, Influence = influence, Creativity = creativity, Threat = threat,
                                      `ICT Index` = ict_index, Starts = starts, xG = expected_goals, xA = expected_assists, `xG Involvements` = expected_goal_involvements,
                                      `xG Conceded` = expected_goals_conceded, `Player ID` = Player_ID)

Player_Historic_Stats <- subset(Player_Historic_Stats, select = -c(element_code))

#--------- Saving to CSV ----------

write.csv(Fixtures, "Fixtures.csv", row.names =  FALSE)
write.csv(Player_Gameweek_Stats, "Player_Gameweek_Stats.csv", row.names =  FALSE)
write.csv(Player_Historic_Stats, "Player_Historic_Stats.csv", row.names =  FALSE)
write.csv(Player_Info, "Player_Info.csv", row.names =  FALSE)
write.csv(Standings, "Standings.csv", row.names =  FALSE)
