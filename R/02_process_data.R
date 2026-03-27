#-------------------------------------------------------------------------------
# 02_process_data.R
# Define trap collection dates, trap periods, and the formatForCorrespondence
# function; then process and save the formatted data for correspondence analysis
#-------------------------------------------------------------------------------

library(here)
library(almanac)

#-------------------------------------------------------------------------------
# Trap collection dates (last updated 2026.02.04)
trapCollectionDates <- as.Date(c(
  '2019-08-01',
  '2020-07-27',
  '2020-09-17',
  '2021-06-15',
  '2021-08-09',
  '2021-08-26',
  '2021-09-21',
  '2021-10-06',
  '2022-06-24',
  '2022-08-31',
  '2022-09-01',
  '2022-09-12',
  '2022-09-14',
  '2023-07-03',
  '2023-07-31',
  '2023-08-14',  # 2 at this date
  '2023-08-31',
  '2023-09-25',
  '2023-09-29',
  '2023-10-12',
  '2024-08-06',
  '2024-09-17',  # 2 at this date
  '2025-06-09',  # 2 at this date
  '2025-08-05',
  '2025-08-18',
  '2025-09-30'   # 4 at this date
))

#-------------------------------------------------------------------------------
# Trap monitoring periods by year
trapPeriods <- list(
  Y2022 = list(start = '2022-06-07', end = '2022-11-14'),
  Y2023 = list(start = '2023-06-05', end = '2023-11-23'),
  Y2024 = list(start = '2024-05-13', end = '2024-11-22'),
  Y2025 = list(start = '2025-05-27', end = '2025-11-25')
)

#-------------------------------------------------------------------------------
# Format import shipment data into a long table suitable for correspondence
# analysis, aligned to discrete trap-monitoring time windows.
#
# Parameters:
#   trapCollectionDates  Date vector of actual trap collection events
#   shipData             Data frame of import shipment records
#   entityCol            Column name for the entity grouping variable
#   countryCol           Column name for country of origin
#   commodityCol         Column name for commodity description
#   dateCol              Column name for the shipment review date
#   trapPeriods          Named list; each element has $start and $end (strings)
#   timePeriodTraps      Look-back window in days for trap detection (default 7)
#   timePeriodShips      Look-back window in days for shipment data (default =
#                        timePeriodTraps)
#   outPrefixFileName    Prefix for output file names (reserved for future use
#                        when callers save output directly from this function)
#
# Returns:
#   A data frame with columns: date, trapResult, country, commodity
formatForCorrespondence <- function(trapCollectionDates,
                                    shipData,
                                    entityCol        = "EntityCol",      # reserved for future entity-level filtering
                                    countryCol       = "PG32_Country_Name",
                                    commodityCol     = "CBP.Line...HTS.Description",
                                    dateCol          = "myMS_Review_Date",
                                    trapPeriods,
                                    timePeriodTraps  = 7,   # in days; 7 = 1 week
                                    timePeriodShips  = timePeriodTraps,
                                    outPrefixFileName = "Test") {

  # Build the sequence of period end-dates across all trap seasons
  periodDates <- as.Date(character(0))
  for (x in trapPeriods) {
    trapPeriodRule <- daily(since = x$start, until = x$end) %>%
      recur_on_interval(timePeriodTraps)
    theseDates <- alma_search(from = x$start, to = x$end, rschedule = trapPeriodRule)
    theseDates <- theseDates[-1]  # Drop the first date; we look backwards to summarize
    periodDates <- c(periodDates, theseDates)
  }

  colNames <- c('date', 'trapResult', 'country', 'commodity')
  output   <- as.data.frame(matrix(ncol = 4, nrow = 0))
  names(output) <- colNames

  # Cycle through each period end-date and summarize shipments
  for (x in seq_along(periodDates)) {

    endDate        <- as.Date(periodDates[x])
    startDateTrap  <- endDate - timePeriodTraps
    startDateShip  <- endDate - timePeriodShips

    trapResult <- if (any(trapCollectionDates > startDateTrap &
                          trapCollectionDates <= endDate)) { 1 } else { 0 }

    # Subset shipment records that fall within the look-back window
    shipRows <- which(shipData[, dateCol] > startDateShip &
                        shipData[, dateCol] <= endDate)
    subShip  <- unique(shipData[shipRows, c(countryCol, commodityCol)])

    if (nrow(subShip) > 0) {
      names(subShip)      <- c('country', 'commodity')
      subShip$trapResult  <- trapResult
      subShip$date        <- as.Date(endDate, format = '%m/%d/%Y')
      subShip             <- subShip[, colNames]
      output              <- rbind(output, subShip)
    }
  }

  return(output)
}

#-------------------------------------------------------------------------------
# Load processed raw data, apply formatting, and save results

pg32Data <- readRDS(here::here("data", "processed", "pg32Data.rds"))

# All-traps formulation (7-day trap window, 30-day shipment window)
formatData.pg32.AllTraps <- formatForCorrespondence(
  trapCollectionDates = trapCollectionDates,
  shipData            = pg32Data,
  trapPeriods         = trapPeriods,
  timePeriodTraps     = 7,
  timePeriodShips     = 30
)

saveRDS(formatData.pg32.AllTraps,
        file = here::here("data", "processed", "formatData_pg32_AllTraps.rds"))

message("Formatted correspondence data saved to data/processed/formatData_pg32_AllTraps.rds")
