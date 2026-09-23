assert_project_root <- function() {
  if (!file.exists("L2vocab.Rproj")) {
    stop("Run this script from the repository root.", call. = FALSE)
  }
}

ensure_directories <- function() {
  paths <- c(
    "data/interim",
    "data/processed",
    "figures",
    "output/models",
    "output/tables",
    "output/diagnostics"
  )
  invisible(lapply(paths, dir.create, recursive = TRUE, showWarnings = FALSE))
}

condition_levels <- c("Control", "Thematic", "Grounding")
time_levels <- c("Pretest", "Post-test")

