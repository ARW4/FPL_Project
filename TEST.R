env_private_key = Sys.getenv("PRIVATE_KEY")

env_private_key <- substr(env_private_key,0,100)

df <- data.frame(env_private_key)

write.csv(df, "Test.csv", row.names =  FALSE)
