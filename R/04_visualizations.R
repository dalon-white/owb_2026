#-------------------------------------------------------------------------------
# 04_visualizations.R
# Generate and save additional visualizations from the correspondence analysis
#-------------------------------------------------------------------------------

library(here)
library(CA3variants)

#-------------------------------------------------------------------------------
# Load the fitted CA3 model saved during the analysis step
# (Re-fit here from processed data if the model object is not persisted)
formatData.pg32.AllTraps <- readRDS(
  here::here("data", "processed", "formatData_pg32_AllTraps.rds")
)

contingency.pg32.AllTraps <- table(formatData.pg32.AllTraps[, c(2, 3, 4)])

ca3.pg32.AllTraps <- CA3variants(contingency.pg32.AllTraps,
                                  ca3type = 'NSCA3',
                                  resp    = 'row',
                                  dims    = c(2, 4, 4))

#-------------------------------------------------------------------------------
# Biplot — row component (trap result)
png(filename = here::here("output", "visualizations",
                          paste0("biplot_row_", Sys.Date(), ".png")),
    width = 800, height = 800)
plot(ca3.pg32.AllTraps, biptype = "row", addlines = FALSE, scaleplot = 15)
dev.off()

# Biplot — column component (country)
png(filename = here::here("output", "visualizations",
                          paste0("biplot_col_", Sys.Date(), ".png")),
    width = 800, height = 800)
plot(ca3.pg32.AllTraps, biptype = "col", addlines = FALSE, scaleplot = 15)
dev.off()

# Biplot — tube component (commodity)
png(filename = here::here("output", "visualizations",
                          paste0("biplot_tube_", Sys.Date(), ".png")),
    width = 800, height = 800)
plot(ca3.pg32.AllTraps, biptype = "tube", addlines = FALSE, scaleplot = 15)
dev.off()

message("Visualizations saved to output/visualizations/")
