#-------------------------------------------------------------------------------
# 01_load_data.R
# Load raw import data and perform initial formatting
#-------------------------------------------------------------------------------

library(here)

#-------------------------------------------------------------------------------
# PG32 parameter import data
pg32FileName <- '01-imports_PG32_origin_2026.02.04.csv'
pg32DirFileName <- here::here("data", "raw", pg32FileName)
pg32Data <- read.csv(pg32DirFileName)

# Apply initial column adjustments
pg32Data$EntityCol <- 1  # Placeholder until entity data is available
pg32DateCol <- "myMS_Review_Date"
pg32Data[, pg32DateCol] <- as.Date(pg32Data[, pg32DateCol], format = '%m/%d/%Y')

#-------------------------------------------------------------------------------
# Save the loaded (lightly formatted) data to processed folder
saveRDS(pg32Data, file = here::here("data", "processed", "pg32Data.rds"))

message("Data loaded and saved to data/processed/pg32Data.rds")
