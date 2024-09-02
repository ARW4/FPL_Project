#---------- Setting Up Environment ---------
#rm(list = ls())
#cat("\014")

#install.packages(c("conflicted","tidyverse","progress","remotes","dplyr"))
#install.packages("remotes")
# remotes::install_github("ewenme/fplr")
# install.packages("htmltools")
#install.packages("rvest")

library(rvest)
library(remotes)
library(conflicted)
conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")

library(tidyverse)
library(progress)
library(fplr)
library(dplyr)


#---------- Downloading Team Fixtures ---------
# Downloading fixtures table
df_fixtures <- data.frame(fpl_get_fixtures()) 

# Pivoting team id
df_fixtures <- pivot_longer(df_fixtures, cols = c(team_a, team_h), names_to = "team_type", values_to = "team")
df_fixtures <- pivot_longer(df_fixtures, cols = c(team_a_score, team_h_score), names_to = "team_score", values_to = "score")

# keeping only relevant columns
df_fixtures <- subset(df_fixtures, select = c(id, code, event, finished, kickoff_time,
                                              team_type, team, team_a_difficulty, team_h_difficulty,
                                              team_score, score))

# renaming columns for join
df_fixtures <- df_fixtures %>% rename( match_id = id, id = team)

# Downloading teams table
df_teams <- data.frame(fpl_get_teams())

# Joining teams table and fixtures table together on id
Fixtures <- inner_join(df_fixtures, df_teams, join_by( id == id))

# Tidying Environment
rm(df_fixtures, df_teams)

# keeping only relevant columns
Fixtures <- subset(Fixtures, select = c(match_id, team_type, name, event, finished, kickoff_time, strength, team_score, score))

# Find and replace
Fixtures <- Fixtures %>% mutate(team_score = gsub("_score", "", team_score))

# Keeping only one row for each match and team
Fixtures <- Fixtures[Fixtures$team_score == Fixtures$team_type,]

# Pivoting fields
Fixtures <- pivot_wider(Fixtures, names_from = c(team_type, team_score) , values_from = c(name, strength, score))

# Renaming fields
Fixtures <- Fixtures %>% rename(`Match ID` = match_id,
                                Matchday = event,
                                Finished = finished,
                                Date = kickoff_time,
                                `Away Team` = name_team_a_team_a,
                                `Home Team` = name_team_h_team_h,
                                `Away Team Strength` = strength_team_a_team_a,
                                `Home Team Strength` = strength_team_h_team_h,
                                `Away Team Score` = score_team_a_team_a,
                                `Home Team Score` = score_team_h_team_h
                                )


#---------- Creating Player Info Table ----------
`Player Info` <- data.frame(fpl_get_player_all())
`Team Info` <- data.frame(fpl_get_teams())
`Team Info` <- subset(`Team Info`, select = c(name, id))
`Player Info` <- inner_join(`Player Info`, `Team Info`, join_by(team == id))

`Player Info` <- subset(`Player Info`, select = c(id, first_name, second_name, name, element_type, now_cost, total_points, bonus, selected_by_percent, 
                                                  goals_scored, assists, minutes, clean_sheets, goals_conceded, own_goals,
                                                  penalties_saved, penalties_missed, yellow_cards, red_cards, saves, starts, expected_goals, expected_assists,
                                                  expected_goal_involvements, expected_goals_conceded, corners_and_indirect_freekicks_order, direct_freekicks_order,
                                                  penalties_order, form))

`Player Info` <- `Player Info` %>% rename (`First Name` = first_name, 
                                           `Player ID` = id,
                                           `Second Name` = second_name, 
                                           Team = name, 
                                           Position = element_type, 
                                           `Current Cost` = now_cost, 
                                           `Total Points` = total_points, 
                                           `Bonus Points` = bonus, 
                                           `Selected %` = selected_by_percent, 
                                           `Goals Scored` = goals_scored, 
                                           Assists = assists,
                                           Minutes = minutes, 
                                           `Clean Sheets` = clean_sheets, 
                                           `Goals Conceded` = goals_conceded, 
                                           `Own Goals` = own_goals,
                                           `Penalties Saveed` = penalties_saved, 
                                           `Penalties Missed` = penalties_missed, 
                                           `Yellow Cards` = yellow_cards, 
                                           `Red Cards` = red_cards, 
                                           Saves = saves, 
                                           Starts = starts, 
                                           xG = expected_goals, 
                                           xA = expected_assists,
                                           `xG Involvements` = expected_goal_involvements, 
                                           `xG Conceded` = expected_goals_conceded, 
                                           `Corners and Indirect Freekicks Order` = corners_and_indirect_freekicks_order, 
                                           `Direct Freekicks Order` = direct_freekicks_order,
                                           `Penalties Order` = penalties_order, 
                                           Form = form
                                           
)

rm(`Team Info`)

# Replace numerical values with textual descriptions
`Player Info`$Position[`Player Info`$Position == 1] <- "Goalkeeper"
`Player Info`$Position[`Player Info`$Position == 2] <- "Defender"
`Player Info`$Position[`Player Info`$Position == 3] <- "Midfielder"
`Player Info`$Position[`Player Info`$Position == 4] <- "Forward"


#---------- Downloading Player Data ---------
# Downloading data for all players
IDs <- data.frame(`id` = fpl_get_player_all()[["id"]])

# Only keeping 2 top IDs from table
#IDs <- head(IDs, 2)

# Creating empty data frames to then fill in loop 
`Player Current Season Stats` <- data.frame()
`Player Historic Season Stats` <- data.frame()

# Creating progress bar
pb_1 <- progress_bar$new( total = nrow(IDs))

# Creating loop
for (id in IDs$id) {
  
  id <- IDs$id[id]
  
  # Downloading player detailed table
  player_detailed <- fpl_get_player_detailed(player_id = id)
  
  # Extracting History table
  player_detailed <- player_detailed$history %>% as.data.frame()

  if (nrow(player_detailed) > 0) {
  
  # Creates new column with player ID
  player_detailed[,"Player ID"] <- id
  
  # Union new rows onto table
  `Player Current Season Stats` <- rbind(`Player Current Season Stats`, player_detailed)
  
  # Update progress bar
  pb_1$tick()
  }
}

rm(pb_1, player_detailed)

# Creating progress bar
pb_2 <- progress_bar$new( total = nrow(IDs))

# Creating loop
for (id in IDs$id) {
  
  # Downloading player detail table
  player_detailed <- fpl_get_player_detailed(player_id = id)
  
  # Extracting history table
  player_history_past <- player_detailed$history_past %>% as.data.frame()
  
  # if no data then skip adding player id in column
  if (nrow(player_history_past) > 0) {
    
      player_history_past[, "Player ID"] <- id
      
      `Player Historic Season Stats` <- rbind(`Player Historic Season Stats`, player_history_past)
  }
  
  # Updating progress bar
  pb_2$tick()
}

rm(pb_2, player_detailed, player_history_past,id,IDs)


df <- left_join(`Player Current Season Stats`, `Player Info`, join_by(`Player ID` == `Player ID`))
df_1 <- left_join(df, Fixtures, join_by( fixture == `Match ID`))

`Player Current Season Stats` <- subset(df_1, select = c(total_points, was_home, minutes, goals_scored,
                                                         assists, clean_sheets, goals_conceded, own_goals, penalties_saved, penalties_missed,
                                                         yellow_cards, red_cards, saves, bonus, bps, influence, creativity, threat, ict_index, 
                                                         starts, expected_goals, expected_assists, expected_goal_involvements, expected_goals_conceded, 
                                                         transfers_in, transfers_out, `Player ID`, xG, xA, Matchday, Date, `Away Team`, `Home Team`, 
                                                         `Away Team Strength`, `Home Team Strength`, `Away Team Score`, `Home Team Score`)
)

rm(df, df_1)

# Only keeping need columns for Player History table
`Player Historic Season Stats` <- subset(`Player Historic Season Stats`, select = c(`Player ID`, season_name, start_cost, end_cost, starts, minutes, total_points, bonus, 
                                                        expected_goals, goals_scored, expected_assists, assists, yellow_cards, red_cards, 
                                                        penalties_missed, clean_sheets, goals_conceded, own_goals, penalties_saved,saves, 
                                                        expected_goal_involvements, expected_goals_conceded))

# Renaming fields
`Player Historic Season Stats` <- `Player Historic Season Stats` %>% rename (Season = season_name, 
                                                 `Start Cost` = start_cost, 
                                                 `End Cost` = end_cost, 
                                                 `Total Points` = total_points, 
                                                 Minutes = minutes, 
                                                 `Goals Scored` = goals_scored, 
                                                 Assists = assists, 
                                                 `Clean Sheets` = clean_sheets, 
                                                 `Goals Conceded` = goals_conceded, 
                                                 `Own Goals` = own_goals, 
                                                 `Penalties Saved` = penalties_saved, 
                                                 `Penalties Missed` = penalties_missed, 
                                                 `Yellow Cards` = yellow_cards, 
                                                 `Red Cards` = red_cards, 
                                                 Saves = saves, 
                                                 `Bonus Points` = bonus, 
                                                 Starts = starts, 
                                                 xG = expected_goals, 
                                                 xA = expected_assists,
                                                 `XG Involvements` = expected_goal_involvements, 
                                                 `XG Conceded` = expected_goals_conceded)


#--------- Downloading Premier League Table ----------

html <- read_html("https://www.bbc.co.uk/sport/football/premier-league/table")

df_standings <- data.frame(
  html %>% 
    html_element("table") %>% 
    html_table()
)

Standings <- subset(df_standings, select = c(Position, Team, Played, Won, Drawn, Lost, Goals.For, Goals.Against, Goal.Difference, Points))

Standings <- Standings %>% rename(`Goals For` = Goals.For,
                                  `Goals Against` = Goals.Against,
                                  `Goal Difference` = Goal.Difference)

rm(df_standings, html)


#---------- Writing to CSV ----------
# Setting folder to save into

# Writing data frames to csv
write.csv(Standings, "Standings.csv", row.names =  FALSE)
write.csv(Fixtures, "Fixtures.csv", row.names = FALSE)
write.csv(`Player Historic Season Stats`, "Player_Historic_Season_Stats.csv", row.names = FALSE)
write.csv(`Player Current Season Stats`, "Player_Current_Season_Stats.csv", row.names = FALSE)
write.csv(`Player Info`, "Player_Info.csv", row.names = FALSE)

#---------- END OF SCRIPT ----------
