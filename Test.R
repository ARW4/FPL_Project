library(dplyr)
#key <- Sys.getenv("env_private_key")
#key <- substr(key, 1,30)

#key <- data_frame(key) 

# Create two vectors for the columns
column1 <- c(1, 2)
column2 <- c("A", "B")

# Create the data frame
Key <- data.frame(column1, column2)

write.csv(Key, file = "Key.csv")
