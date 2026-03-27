#-------------------------------------------------------------------------------
# pipeline.R
# Master pipeline to run the full OWB import correspondence analysis workflow
#-------------------------------------------------------------------------------

library(here)

#' Run the full analysis pipeline
#'
#' Sources each numbered R script in order:
#'   01 — Load raw CSV data and save to processed/
#'   02 — Format data for correspondence analysis and save to processed/
#'   03 — Fit NSCA3 model and save Excel output to output/data/
#'   04 — Generate and save visualizations to output/visualizations/
#'
#' Optionally renders the final Rmd report and saves the HTML to
#' output/reports/.
#'
#' @param render_report Logical. If TRUE, render the correspondence analysis
#'   Rmd report to HTML and copy it to output/reports/. Requires rmarkdown.
#'   Default is TRUE.
#'
#' @return Invisibly returns a named list of step timings (in seconds).
#'
#' @examples
#' run_pipeline()
#' run_pipeline(render_report = FALSE)
run_pipeline <- function(render_report = TRUE) {

  timings <- list()

  message("=== OWB 2026 Correspondence Analysis Pipeline ===\n")

  # Step 1 — Load raw data
  message("--- Step 1: Loading raw data ---")
  t0 <- proc.time()
  source(here::here("R", "01_load_data.R"), local = new.env())
  timings$load_data <- (proc.time() - t0)[["elapsed"]]
  message("Step 1 complete (", round(timings$load_data, 1), " s)\n")

  # Step 2 — Process / format data
  message("--- Step 2: Processing and formatting data ---")
  t0 <- proc.time()
  source(here::here("R", "02_process_data.R"), local = new.env())
  timings$process_data <- (proc.time() - t0)[["elapsed"]]
  message("Step 2 complete (", round(timings$process_data, 1), " s)\n")

  # Step 3 — Run correspondence analysis and save data output
  message("--- Step 3: Running correspondence analysis ---")
  t0 <- proc.time()
  source(here::here("R", "03_analysis.R"), local = new.env())
  timings$analysis <- (proc.time() - t0)[["elapsed"]]
  message("Step 3 complete (", round(timings$analysis, 1), " s)\n")

  # Step 4 — Generate visualizations
  message("--- Step 4: Generating visualizations ---")
  t0 <- proc.time()
  source(here::here("R", "04_visualizations.R"), local = new.env())
  timings$visualizations <- (proc.time() - t0)[["elapsed"]]
  message("Step 4 complete (", round(timings$visualizations, 1), " s)\n")

  # Step 5 — Render Rmd report (optional)
  if (render_report) {
    if (!requireNamespace("rmarkdown", quietly = TRUE)) {
      warning("rmarkdown is not installed; skipping report rendering.")
    } else {
      message("--- Step 5: Rendering analysis report ---")
      t0 <- proc.time()

      rmd_src   <- here::here("reports", "correspondence_analysis.Rmd")
      html_out  <- here::here("output", "reports",
                              paste0("correspondence_analysis_", Sys.Date(), ".html"))

      rmarkdown::render(
        input       = rmd_src,
        output_file = html_out,
        quiet       = FALSE
      )

      timings$render_report <- (proc.time() - t0)[["elapsed"]]
      message("Step 5 complete (", round(timings$render_report, 1), " s)")
      message("Report saved to: ", html_out, "\n")
    }
  }

  total <- sum(unlist(timings))
  message("=== Pipeline complete — total time: ", round(total, 1), " s ===")

  invisible(timings)
}
