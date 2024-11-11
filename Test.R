library(dplyr)
Key <- Sys.getenv("env_private_key")
Key <- substr(key, 1,30)

Key <- data_frame(key) 

write.csv(Key, file = "Key.csv")
