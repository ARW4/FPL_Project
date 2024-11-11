library(dplyr)
Key <- Sys.getenv("env_private_key")
Key <- substr(Key, 1,30)

Key <- data_frame(Key) 

write.csv(Key, file = "Key.csv")
