library(dplyr)
key <- Sys.getenv("env_private_key")
key <- substr(key, 1,30)

key <- data_frame(key)

write.csv(key, file = "key.csv")
