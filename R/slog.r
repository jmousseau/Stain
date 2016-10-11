#' Slurm Logging
#'
#' A log can be kept for a certain slurm job. A Stain object must be provided or
#' else the \code{.__current_stain_object__} will be used
#'
#' @param ... Zero or more objects which can be coerced to character.
#'
#' @param stain A Stain object. Defaults to \code{.__current_stain_object__}.
#'
#' @export
slog <- function(..., stain = .__current_stain_object__) {
    args <- list(...)

    slog_file <- slog_file(stain)

    for (arg in args) {
        cat(arg, file = slog_file, append = TRUE, sep = "\n")
    }

    invisible()
}


#' Create Slum Logging File
#'
#' @param stain A Stain object.
create_slog_file <- function(stain) {
    slog_file <- slog_file(stain)
    dir.create(dirname(slog_file), recursive = TRUE)
    file.create(slog_file)
}


#' Slurm Logging File
#'
#' @param stain A Stain object.
slog_file <- function(stain) {
    path <- paste0(stain$get_id(), ".txt")
    path <- paste(stain$dir, ".stain", "logs", path, sep = "/")
    return(path)
}
