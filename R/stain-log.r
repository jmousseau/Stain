#' Create Slum Logging File
#'
#' @param stain A Stain object.
create_slog_file <- function(stain) {
    log_id <- rand_alphanumeric(12)
    slog_file <- slog_file(stain, log_id)
    dir.create(dirname(slog_file), recursive = TRUE, showWarnings = FALSE)
    file.create(slog_file)
    return(log_id)
}


#' Slurm Logging File
#'
#' @param stain A Stain object.
#'
#' @param log_id A unique identifier for the log file.
slog_file <- function(stain, log_id) {
    file <- paste0(log_id, ".txt")
    path <- paste(stain$dir, ".stain", "logs",stain$get_id(), file, sep = "/")
    return(path)
}
