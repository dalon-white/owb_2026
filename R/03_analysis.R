#-------------------------------------------------------------------------------
# 03_analysis.R
# Run the three-way non-symmetric correspondence analysis (NSCA3) on the
# formatted import data and save the inner-product results to an Excel file
#-------------------------------------------------------------------------------

library(here)
library(CA3variants)
library(openxlsx)

#-------------------------------------------------------------------------------
# Load formatted data
formatData.pg32.AllTraps <- readRDS(
  here::here("data", "processed", "formatData_pg32_AllTraps.rds")
)

#-------------------------------------------------------------------------------
# Build the three-way contingency table
# Dimensions: trapResult (row) x country (column) x commodity (tube)
contingency.pg32.AllTraps <- table(formatData.pg32.AllTraps[, c(2, 3, 4)])

# Inspect dimensions to confirm ordering:
#   dim 1 -> trap result (row / term I)
#   dim 2 -> country     (column / term J)
#   dim 3 -> commodity   (tube / term K)
message("Contingency table dimensions: ", paste(dim(contingency.pg32.AllTraps), collapse = " x "))

#-------------------------------------------------------------------------------
# Tune the number of dimensions for the NSCA3 model
# Response variable is the row (trap result)
tune.pg32.AllTraps <- tunelocal(contingency.pg32.AllTraps,
                                ca3type = 'NSCA3',
                                resp    = 'row')
# Save the tuning plot
png(filename = here::here("output", "visualizations",
                          paste0("tune_pg32_AllTraps_", Sys.Date(), ".png")),
    width = 800, height = 600)
plot(tune.pg32.AllTraps)
dev.off()

#-------------------------------------------------------------------------------
# Fit the NSCA3 model with chosen dimensions (2, 4, 4)
# - dims = c(2, 4, 4) provides good separation of the trap-result dimension
# - Increasing the country/commodity dims to 5 pushes explained inertia > 70 %
#   (Beh & Lombardo threshold), but 4 keeps the model parsimonious
ca3.pg32.AllTraps <- CA3variants(contingency.pg32.AllTraps,
                                  ca3type = 'NSCA3',
                                  resp    = 'row',
                                  dims    = c(2, 4, 4))
print(ca3.pg32.AllTraps)

# Biplot of the row (trap-result) component
png(filename = here::here("output", "visualizations",
                          paste0("biplot_pg32_AllTraps_row_", Sys.Date(), ".png")),
    width = 800, height = 800)
plot(ca3.pg32.AllTraps, biptype = "row", addlines = FALSE, scaleplot = 15)
dev.off()

#-------------------------------------------------------------------------------
# Save inner-product matrix (strength of association) to Excel
myToday           <- as.character(Sys.Date())
outPrefixFileName <- 'correspondence_commodity_country_2.4.4dims'
outfile           <- paste0(outPrefixFileName, '_', myToday, '.xlsx')
outDirFile        <- here::here("output", "data", outfile)

wb <- createWorkbook(outPrefixFileName)
addWorksheet(wb, sheetName = myToday)
writeData(wb, myToday,
          x        = t(ca3.pg32.AllTraps$iproductijk),
          rowNames = TRUE)
saveWorkbook(wb, file = outDirFile, overwrite = TRUE)

message("Inner-product results saved to: ", outDirFile)
