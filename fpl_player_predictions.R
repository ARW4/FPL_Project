## ----dependencies---------------------------------------------------------------------------------------------------------
library("googlesheets4")
library("dplyr")
library("zoo")
library("stringr")
library("ggplot2")
library("factoextra")
library("janitor")
library("tibble")
library("httr")
library("jsonlite")
library("purrr")
library("broom")
library("tidyr")
library("here")
library("utils")
library("progress")
library("lubridate")
library("readr")
library("future")
library("furrr")


## ----import_data----------------------------------------------------------------------------------------------------------
#---------- Autheticating Google Sheets ----------
# Calling in credentials through github secrest.
json_string <- Sys.getenv("PRIVATE_KEY")

# Authenticating google
gs4_auth(path = json_string)

# Printing stage complete
message("Authenticating Google Sheets Complete")

# Loading tables 
import_gameweek <- data.frame(read_sheet(ss,sheet = "Gameweek"))
import_player <- data.frame(read_sheet(ss,sheet = "Player"))
import_standings <- data.frame(read_sheet(ss,sheet = "Standings"))
import_fixtures <- data.frame(read_sheet(ss,sheet = "Fixtures"))
import_historic <- data.frame(read_sheet(ss,sheet = "Historic Seasons"))



## -------------------------------------------------------------------------------------------------------------------------
# URL for last seasons data
url <- "https://raw.githubusercontent.com/ARW4/FPL_Project/refs/heads/main_branch/2024-25/Gameweek.csv"

# importing last seasons data and cleaning headers and modifying field names for union
import_last_seasons_gameweek<- read_csv(url, show_col_types = FALSE) %>%
  clean_names() %>%
    mutate(across(-c(kick_off_time, modified), as.numeric))

# cleaning import_gameweek for union
import_gameweek <- import_gameweek %>%
  clean_names() %>%
  mutate(across(-c(kick_off_time, modified), as.numeric)) %>%
  mutate(kick_off_time = ymd_hms(kick_off_time))

# Unioning current and last season together
df_all_seasons_gameweeks <- bind_rows(
  "2526" = import_gameweek,
  "2425" = import_last_seasons_gameweek,
  .id = "season"
) %>%
  mutate(
    id = paste0(season, player_id)
  ) 


## -------------------------------------------------------------------------------------------------------------------------
# url for last seasons player data
url <- "https://raw.githubusercontent.com/ARW4/FPL_Project/refs/heads/main_branch/2024-25/Player.csv" 
  
# importing last seasons data and cleaning headers for union
import_last_seasons_player <- read_csv(url, show_col_types = FALSE) %>%
  clean_names() # %>%
  # mutate(
  #   second_name = iconv(second_name, from = "UTF-8", to = "ASCII//TRANSLIT"),
  #   first_name = iconv(first_name, from = "UTF-8", to = "ASCII//TRANSLIT")
  #   )

# cleaning this seasons data for union
import_player <- import_player %>%
  clean_names() %>%
  mutate(
  form = as.double(form),
  news_added = as_datetime(news_added)#,
  #   second_name = iconv(second_name, from = "UTF-8", to = "ASCII//TRANSLIT"),
  #   first_name = iconv(first_name, from = "UTF-8", to = "ASCII//TRANSLIT")
  )

# Unioning seasons data together
df_all_seasons_players <- bind_rows(
  "2526" = import_player,
  "2425" = import_last_seasons_player,
  .id = "season"
) %>%
  mutate(
    id = paste0(season, player_id)
  ) 


## -------------------------------------------------------------------------------------------------------------------------
df_gameweek <- df_all_seasons_gameweeks %>%
  left_join(df_all_seasons_players,
            join_by(id)) %>%
  mutate(
    full_name = paste0(first_name, ", ", second_name)
  )


## -------------------------------------------------------------------------------------------------------------------------
# URL for last seasons data
url <- "https://raw.githubusercontent.com/ARW4/FPL_Project/refs/heads/main_branch/2024-25/Fixtures.csv"

# importing last seasons data, cleaning headers and modifying field names for union
import_last_seasons_fixtures<- read_csv(url, show_col_types = FALSE) %>%
  clean_names()

# cleaning import_gameweek for union
import_fixtures <- import_fixtures %>%
  clean_names() %>%
  mutate(kick_off_time = as_datetime(kick_off_time))

# Unioning current and last season together
df_all_seasons_fixtures <- bind_rows(
  "2526" = import_fixtures,
  "2425" = import_last_seasons_fixtures,
  .id = "season"
)


## -------------------------------------------------------------------------------------------------------------------------
df_player_form <- df_gameweek %>%
  # selecting fields
  select(c(full_name, total_points, kick_off_time, season.x, team_id))%>%
  rename(season = season.x) %>%
  group_by(full_name,season) %>% 
  # ordering by kick-off date | Grouping active
  arrange(kick_off_time, .by_group = TRUE) %>%
  ungroup() %>%
  group_by(full_name, season) %>%
  mutate(
    # creating match sequence
    gameweek = row_number()
    ) %>%
  ungroup() %>%
  group_by(full_name) %>%
  mutate(
    # moving average calculation
    player_form = rollapply(
      total_points,
      width = 3,      # window size for calculating player_form
      FUN = mean,
      partial = TRUE,
      align = "right" )
    )


## -------------------------------------------------------------------------------------------------------------------------
df_team_form <- df_all_seasons_fixtures %>%
  filter(finished == TRUE) %>%
  # selecting fields
  select(season, team, opponent, kick_off_time, home_or_away, home_team_score, away_team_score) %>% 
  # renaming fields
  rename(location = home_or_away,
         kick_off_date = kick_off_time,
         home_score = home_team_score,
         away_score = away_team_score) %>% 
  mutate(
    # creating results based on scores
    result = case_when(
      home_score == away_score ~ "D",
      home_score > away_score & location == "Home" ~ "W",
      home_score < away_score & location == "Home" ~ "L",
      home_score > away_score & location == "Away" ~ "L",
      home_score < away_score & location == "Away" ~ "W") 
    ,
    # creating points based on result
    points = case_when(
      result == "W" ~ 3,
      result == "D" ~ 1,
      result == "L" ~ 0) 
    ,
    # creating score | this is a quality of life field
    score = paste0(home_score, "-", away_score) 
    ,
    kick_off_date = as.Date(kick_off_date)
  ) %>%
  # removing score fields from data frame
  select(-c("home_score", "away_score")) %>% 
  # grouping by team and season
  group_by(team, season) %>% 
  # ordering by kick-off date | Grouping active
  arrange(kick_off_date, .by_group = TRUE) %>% 
  # creating match sequence | Grouping active
  mutate(gameweek = row_number()) %>% 
  # ungrouping all previously defined groupings
  ungroup() %>%
  # grouping by team
  group_by(team) %>%      
  # creating a lag of form - moving average should only be based on previous match   values
  mutate(
    # moving average calculation
    team_form = rollapply(
      points,
      width = 5,  # window size for calculating team_form
      FUN = mean,
      partial = TRUE,
      align = "right" )
    )%>%
  # ungrouping all previously defined groupings
  ungroup() %>% 
  # selecting fields
  select(c(season, gameweek, team, points, team_form)) %>%
  # rounding team_form
  mutate(
    team_form = round(team_form, digits = 2)
  ) %>%
  rename( team_points = points)


## -------------------------------------------------------------------------------------------------------------------------
df_teams <- df_all_seasons_fixtures %>%
  # selecting fields
  select(season, team_id, team) %>%
  # only keeping unqieu combinations
  distinct()

df_opponent <- df_all_seasons_fixtures %>%
  #selecting fields
  select(season, kick_off_time, team, opponent) %>%
  # grouping by team and season
  group_by(season, team) %>%
  # calculating gameweek
  mutate(gameweek = row_number()) %>%
  #ungrouping
  ungroup() %>%
  # unselecting kick_off_time field
  select(-kick_off_time)

df_combined_stats <- df_player_form %>%
  # joining team info
  left_join(df_teams,
            join_by(season, team_id)) %>%
  # joining team form for each player
  left_join(df_team_form,
            join_by(season, gameweek, team)
            ) %>%
  # joining the opponent for each player and gameweek
  left_join(df_opponent,
            join_by(
              season,
              gameweek,
              team
            )) %>%
  # joining team form but using opponent in join clause to get opponent form
  left_join(df_team_form,
            join_by(season, gameweek, opponent == team)) %>%
  # selecting fields
  select(season, gameweek, team, opponent, full_name, player_form, team_form.x, team_form.y) %>%
  # renaming fields
  rename(team_form = team_form.x,
         opponent_form = team_form.y)


## -------------------------------------------------------------------------------------------------------------------------
player_names <- df_all_seasons_players %>%
  #creating full_name
  mutate(full_name = paste0(first_name, ", ", second_name)) %>%
  # selecting fields
  select(id, full_name, position)

df_all_seasons_gameweeks <- df_all_seasons_gameweeks %>%
  #joining player names
  left_join(player_names,
            join_by(id))

df_all_seasons_gameweeks <- df_all_seasons_gameweeks %>%
  #group by season and name
  group_by(season, full_name) %>%
  # sorting by kick_off_time
  arrange(kick_off_time) %>%
  # creating gameweek
  mutate(calc_gameweek = row_number())

df_all_stats <- df_combined_stats %>%
  #joining gameweek data and the newly created form stats
  left_join(df_all_seasons_gameweeks,
            join_by(season, gameweek == calc_gameweek,full_name))


## -------------------------------------------------------------------------------------------------------------------------
df_for_modelling_lags <- df_all_stats %>%
  # only include data where players have at least 1 minute of gametime
  filter(minutes != 0) %>%
  # selecting fields
  select(
    season,
    gameweek,
    full_name, 
    position,
    player_form,
    team_form,
    opponent_form,
    total_points,
    goals_scored,
    assists,
    clean_sheets,
    goals_conceded,
    own_goals,
    penalties_saved,
    penalties_missed,
    yellow_cards,
    red_cards,
    saves,
    bonus,
    bps,
    influence,
    creativity,
    threat,
    ict_threat,
    clearances_blocks_interceptions,
    recoveries,
    tackles,
    defensive_contribution,
    x_g,
    x_a,
    x_g_involvements,
    x_g_conceded
  ) %>%
  # convert everything that is numeric into a numeric data type
  mutate_if(is.numeric, as.numeric) %>%
  mutate(season = as.numeric(season)) %>%
  #group by each player
  group_by(full_name) %>%
  # sort by season and gameweek
  arrange(season, gameweek) %>%
  # create a lag for all variables
  mutate(across(where(is.numeric), .fns = list(lag = ~ lag(.x, n = 1)))) %>%
  # ungroup
  ungroup()


## -------------------------------------------------------------------------------------------------------------------------
df_predicting_data <- df_all_stats %>%
  # selecting fields
  select(
    season,
    gameweek,
    full_name, 
    position,
    player_form,
    team_form,
    opponent_form,
    total_points,
    goals_scored,
    assists,
    clean_sheets,
    goals_conceded,
    own_goals,
    penalties_saved,
    penalties_missed,
    yellow_cards,
    red_cards,
    saves,
    bonus,
    bps,
    influence,
    creativity,
    threat,
    ict_threat,
    clearances_blocks_interceptions,
    recoveries,
    tackles,
    defensive_contribution,
    x_g,
    x_a,
    x_g_involvements,
    x_g_conceded
  ) %>%
  mutate_if(is.numeric, as.numeric) %>%
  mutate(season = as.numeric(season)) %>%
  group_by(full_name) %>%
  arrange(season, gameweek) %>%
  mutate(across(where(is.numeric), .fns = list(lag = ~ lag(.x, n = 1)))) %>%
  ungroup() %>%
  filter(season == max(season)) %>%
  filter(gameweek == max(gameweek)) %>%
  mutate(gameweek = gameweek + 1) %>%
  select(season, gameweek, full_name, position, !contains("_lag")) %>%
  rename_with(~ str_c(., "_lag"), where(is.numeric))


## -------------------------------------------------------------------------------------------------------------------------
# Extracting all lag variables
lag_vars <- names(df_for_modelling_lags)[grepl("_lag$", names(df_for_modelling_lags))]

# Deciding which variables should always stay in the model
constant_lags <- c("player_form_lag", "team_form_lag", "opponent_form_lag")

# Removing constant_lags from list of all lag variables
combinable_lags <- setdiff(lag_vars, constant_lags)

# Creating all possible combinations of variables.
combinations <- combn(combinable_lags, m = 2, simplify = FALSE)

# Generate unique list of positions
unique_positions <- unique(df_for_modelling_lags$position)

# Empty list will hold models in
list_all_models <- list()

# Outer loop: Loop through each position
for (current_position in unique_positions) {
  
  # Empty list to store models for the current position
  position_models_list <- list()

  # Filter the training data for the current position
  df_position <- df_for_modelling_lags %>%
    filter(position == current_position)

  # Inner loop: Loop through each combination of variables
  for (i in seq_along(combinations)) {
    
    # Get the current pair of lag variables
    current_pair <- combinations[[i]]
    var1 <- current_pair[1]
    var2 <- current_pair[2]

    # Create the formula string dynamically
    fixed_predictors <- paste(constant_lags, collapse = " + ")
    formula_str <- paste0("total_points ~ ", var1, "+", var2, "+ ", fixed_predictors)
    model_formula <- as.formula(formula_str)

    # Run the model using df_position
    current_model <- lm(model_formula, data = df_position)

    # Store model name in a list
    model_name <- paste0("model_", var1, "-", var2)
    position_models_list[[model_name]] <- current_model
  }

  # Add the list of models for the current position to the main list
  list_all_models[[current_position]] <- position_models_list
  
  # Message to terminal
  cat("Processed models for position:", current_position, "\n")
}

# Creating list
objects_to_remove <- c("position_models_list", "df_position", "current_pair", "var1", "var2", "fixed_predictors", "formula_str", "model_formula", "current_model", "model_name", "i", "lag_vars","current_position", "constant_lags", "combinable_lags", "combinations","unique_positions", "objects_to_remove")

# Cleaning environment
rm(list = objects_to_remove)


## -------------------------------------------------------------------------------------------------------------------------

# Initialize an empty list to store results
list_all_model_summaries <- list()

# Loop through positions
for (pos_name in names(list_all_models)) {
  
  # Creating a list of all models for position
  position_list <- list_all_models[[pos_name]]

  # Loop through models within each position
  for (model_name in names(position_list)) {
    
    # List holds model summary 
    model <- position_list[[model_name]]

    # Create one row with model summary
    glance_stats <- glance(model) %>%
      mutate(
        model_name = model_name,
        position = pos_name
      )%>%
      select(r.squared, adj.r.squared, statistic, p.value, df, nobs) %>%
      mutate(
        model_name = model_name,
        position = pos_name
      ) %>%
      select(position, model_name, everything())

    list_all_model_summaries[[paste0(pos_name, "_", model_name)]] <- glance_stats
  
  }
  # Message to terminal
  cat("Processed models for position: ", pos_name, "\n")
}

# Combine all model summaries into a data frame
df_model_summaries <- bind_rows(list_all_model_summaries)

# Creating list
objects_to_remove <- c("list_all_model_summaries", "position_list", "model", "glance_stats", "objects_to_remove", "model_name", "pos_name")

# Cleaning environment
rm(list = objects_to_remove)


## -------------------------------------------------------------------------------------------------------------------------
# Selecting the models with the highest R_Squared
df_top_models <- df_model_summaries %>%
  group_by(position) %>%
  arrange(desc(r.squared)) %>%
  slice(1) %>%
  ungroup()

print(df_top_models)


## -------------------------------------------------------------------------------------------------------------------------
# Empty list for predictions
list_model_predictions <- list()

# Unique list of positions 
unique_positions <- unique(df_top_models$position)

# Outer loop: Loop through each position
for (current_position in unique_positions) {

  # Filter to get model for current position
  top_model_for_position <- df_top_models %>%
    filter(position == current_position) %>%
    pull(model_name) 
  
  # Filter the data for the current position
  df_predicting_data_position <- df_predicting_data %>%
    filter(position == current_position)

  # Check if the model exists in list_all_models for this position
  current_model <- list_all_models[[current_position]][[top_model_for_position]]
  
  # Generate predictions on the filtered test data
  predictions <- predict(current_model, newdata = df_predicting_data_position)
  
  # Create a temporary dataframe for the current model's results
  temp_df <- data.frame(
    full_name = df_predicting_data_position$full_name
    ,position = current_position
    ,gameweek = df_predicting_data_position$gameweek_lag
    ,predicted_points = predictions
    ,model_name = top_model_for_position
    )
  
  # Add the temporary dataframe to the list of all results
  list_model_predictions[[paste0(current_position, "_", top_model_for_position)]] <- temp_df
}

cat("Finished predicting\n")

# Combine all model predictions into one
df_predictions <- bind_rows(list_model_predictions)

# Creating list
objects_to_remove <- c("unique_positions", "top_model_for_position", "current_model", "predictions", "temp_df","current_position", "objects_to_remove")

# Cleaning environment
rm(list = objects_to_remove)


## ----setting_dream_team_formation-----------------------------------------------------------------------------------------

# Initialize an empty data frame to store the formations
df_formation <- data.frame(
  formation_name = character(),
  stringsAsFactors = FALSE
)

# Define number of players in each position
min_def <- 3
max_def <- 5
min_mid <- 2
max_mid <- 5
min_fwd <- 1
max_fwd <- 3

# Loop through possible combinations of Defenders and Midfielders
for (def in min_def:max_def) {
  
  for (mid in min_mid:max_mid) {
    
    # Calculate the number of Forwards needed to make 10 outfield players
    fwd <- 10 - def - mid

    # Check if the calculated number of Forwards is within the valid range
    if (fwd >= min_fwd && fwd <= max_fwd) {
      # If valid, add the formation to the data frame
      new_row <- data.frame(
        Goalkeeper = 1, # GK is always 1
        Defender = def,
        Midfielder = mid,
        Forward = fwd,
        formation_name = paste0(def, "-", mid, "-", fwd),
        stringsAsFactors = FALSE
      )
      df_formation <- bind_rows(df_formation, new_row)
    }
  }
}

df_formation <- df_formation %>%
  pivot_longer(
    cols = c(Goalkeeper,Defender,Midfielder,Forward),
    names_to = "position",
    values_to = "count"
  ) %>%
  group_by(formation_name) %>%
  nest(requirements = c(position, count))

# Creating list
objects_to_remove <- c("objects_to_remove" ,"min_def", "min_mid", "min_fwd", "max_def", "max_mid", "max_fwd", "def", "mid", "fwd", "new_row")

# Cleaning environment
rm(list = objects_to_remove)


## -------------------------------------------------------------------------------------------------------------------------
player_value <- import_player %>%
  mutate(full_name = paste0(first_name,", ",second_name)) %>%
  select(full_name, current_cost)

df_predictions_with_value <- df_predictions %>%
  left_join(player_value,
            join_by(full_name)) %>%
  mutate(value = current_cost/10) %>%
  select(-current_cost) %>%
  group_by(position) %>%
  filter(
        (position == "Goalkeeper" & rank(-predicted_points) <= 5) |
        (position == "Defender" & rank(-predicted_points) <= 15) |
        (position == "Midfielder" & rank(-predicted_points) <= 15) |
        (position == "Forward" & rank(-predicted_points) <= 12)
      ) %>%
  ungroup()


## -------------------------------------------------------------------------------------------------------------------------
plan(multisession, workers = availableCores() - 1)

# Create a list to store results for each cost interval
list_of_best_teams_by_cost <- list()

cat(sprintf("[%s] --- Starting team selection process ---\n", 
            format(Sys.time(), "%H:%M:%S")))

# Create a player lookup table with unique indices per position
players_indexed <- df_predictions_with_value %>%
  group_by(position) %>%
  mutate(player_index = row_number()) %>%
  ungroup()

# Loop through max_team_cost intervals
for (cost in seq(85, 65, by = -5)) {
  
  max_team_cost <- cost
  min_team_cost <- cost - 4.9
  
  # Create a temporary list to store best teams for the current budget
  list_of_best_teams_for_cost <- list()
  
  cat(sprintf("\n[%s] --- Processing for max_team_cost = %d ---\n", 
              format(Sys.time(), "%H:%M:%S"), max_team_cost))
  
  # Loop through each formation
  for (j in 1:nrow(df_formation)) {
    
    formation_name <- df_formation$formation_name[j]
    requirements <- df_formation$requirements[[j]]
    
    cat(sprintf("[%s] Processing formation %d of %d (%s)\n",
                format(Sys.time(), "%H:%M:%S"),
                j, nrow(df_formation), formation_name))
    
    # For each position, find the maximum points for every possible cost.
    position_packs <- map(1:nrow(requirements), ~{
      pos <- requirements$position[.x]
      count <- requirements$count[.x]
      
      # Filter for players in the current position
      available_players <- filter(players_indexed, position == pos)
      
      index_combos <- combn(available_players$player_index, count, simplify = FALSE)
      
      # Use future_map_dfr for parallel execution -- this speeds up looping
      future_map_dfr(index_combos, ~{
        player_selection <- available_players[match(., available_players$player_index), ]
        tibble(
          cost = sum(player_selection$value),
          points = sum(player_selection$predicted_points),
          indices = list(player_selection$player_index)
        )
      }, .options = furrr_options(scheduling = 1)) %>%
        group_by(cost) %>%
        filter(points == max(points)) %>%
        slice(1) %>%
        ungroup() %>%
        rename_with(~ paste0(pos, "_", .x))
    })
    
    all_team_combos <- reduce(position_packs, crossing)
    
    if (nrow(all_team_combos) == 0) next
    
    cost_cols <- names(all_team_combos) %>% str_subset("_cost$")
    points_cols <- names(all_team_combos) %>% str_subset("_points$")
    
    best_team_summary <- all_team_combos %>%
      mutate(
        total_team_cost = rowSums(select(., all_of(cost_cols))),
        total_team_points_predicted = rowSums(select(., all_of(points_cols)))
      ) %>%
      filter(total_team_cost <= max_team_cost,
             total_team_cost >= min_team_cost) %>%
      arrange(desc(total_team_points_predicted)) %>%
      slice(1)
    
    if (nrow(best_team_summary) > 0) {
      list_of_best_teams_for_cost[[formation_name]] <- best_team_summary
    }
  }
  
  # Store the results for the current budget
  list_of_best_teams_by_cost[[as.character(max_team_cost)]] <- list_of_best_teams_for_cost
}

cat(sprintf("\n[%s] --- All formations and budgets processed, rebuilding final dataframe ---\n",
            format(Sys.time(), "%H:%M:%S")))

# Check the new list
if (length(list_of_best_teams_by_cost) > 0) {
  df_all_results <- bind_rows(
    lapply(names(list_of_best_teams_by_cost), function(cost) {
      bind_rows(list_of_best_teams_by_cost[[cost]], .id = "formation") %>%
        mutate(max_team_cost = as.numeric(cost))
    })
  ) %>% 
    select(max_team_cost, formation, total_team_cost, total_team_points_predicted, contains("_indices"))
    
  player_indices_to_get <- df_all_results %>%
    select(max_team_cost, formation, contains("_indices")) %>%
    pivot_longer(
      cols = -c(max_team_cost, formation),
      names_to = "position",
      values_to = "player_index"
    ) %>%
    mutate(position = sub("_indices$", "", position)) %>%
    unnest(player_index)
  
  df_top_team_per_formation <- players_indexed %>%
    inner_join(player_indices_to_get, by = c("position", "player_index"))
  
  df_top_team_per_formation <- df_top_team_per_formation %>%
    left_join(
      df_all_results %>% select(max_team_cost, formation, total_team_cost, total_team_points_predicted),
      by = c("max_team_cost", "formation")
    )
} else {
  df_top_team_per_formation <- tibble()
}

cat(sprintf("[%s] --- Script finished successfully ---\n",
            format(Sys.time(), "%H:%M:%S")))

# Shut down parallel workers
plan(sequential)


## -------------------------------------------------------------------------------------------------------------------------
csv_predicted_best_picks <- df_top_team_per_formation %>%
  group_by(formation, position,max_team_cost) %>%
  arrange(desc(predicted_points)) %>%
  mutate(
    position_code = paste0(substr(first(position),1,1),row_number()),
    team_cost_bracket = paste0(max_team_cost - 4.9, 'm - ', max_team_cost, 'm')
    ) %>%
  ungroup()

write.csv(csv_predicted_best_picks, "predicted_best_picks.csv")

csv_predicted_points <- df_predictions

write.csv(csv_predicted_points, "player_predictions.csv")

# Saving to google sheets
Google_Sheets_Url <- Sys.getenv("GOOGLE_SHEETS_URL")

range_clear(Google_Sheets_Url,
            sheet = "Starting XI",
            range = NULL
)
write_sheet(csv_predicted_best_picks, 
            Google_Sheets_Url,
            sheet = "Starting XI"
)
range_clear(Google_Sheets_Url,
            sheet = "Player Predictions",
            range = NULL
)
write_sheet(csv_predicted_best_picks, 
            Google_Sheets_Url,
            sheet = "Player Predictions"
)


