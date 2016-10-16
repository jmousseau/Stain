#' Slurm Logging
#'
#' A log can be kept for a certain slurm job. A Stain object must be provided or
#' else the \code{.__current_stain_object__} will be used
#'
#' @param ... Zero or more objects which can be coerced to character.
#'
#' @param slog_file A path to a log file Defaults to
#' \code{.__current_stain_log__}.
#'
#' @export
slog <- function(..., slog_file = .__current_stain_log__) {
    args <- list(...)

    for (arg in args) {
        cat(arg, file = slog_file, append = TRUE, sep = "\n")
    }

    invisible()
}


#' Create Slum Logging File
#'
#' @param stain A Stain object.
create_slog_file <- function(stain) {
    log_id <- rand_alphanumeric(12)
    slog_file <- slog_file(stain, log_id)
    dir.create(dirname(slog_file), recursive = TRUE)
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
