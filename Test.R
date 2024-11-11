key <- Sys.getenv("env_private_key")
key <- substr(key, 1,10)

key <- tibble(key)

write.csv(key, file = "key.csv")
