library(dplyr)
Key <- Sys.getenv("PRIVATE_KEY")
Key <- substr(Key, 1,100)

Key <- data_frame(Key) 

write.csv(Key, file = "Key.csv")
