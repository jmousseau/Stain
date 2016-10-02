#' Create the meta JSON file.
#'
#' @param dir The location of the \code{.stain/} directory.
stain_meta_create <- function(dir) {
    if (!dir.exists(dir)) {
        stop("Incorrect stain directory.", call. = FALSE)
    }

    meta_file <- paste0(dir, ".stain/meta.json")
    write("{}", file = meta_file)
}


#' Read tne stain meta file.
#'
#' @param dir The location of the \code{.stain/} directory.
#'
#' @return An R object representing the JSON meta data.
stain_meta_read <- function(dir) {
    if (!dir.exists(dir)) {
        stop("Incorrect stain directory.", call. = FALSE)
    }

    meta_file <- paste0(dir, ".stain/meta.json")

    if (!file.exists(meta_file)) {
        stop("Stain meta file doesn't exist.", call. = FALSE)
    }

    return(jsonlite::fromJSON(meta_file))
}


#' Write tne stain meta file.
#'
#' This method should not be used directly by functions outside this file.
#'
#' @param meta The meta data R object.
#'
#' @param dir The location of the \code{.stain/} directory.
stain_meta_write <- function(meta, dir) {
    if (!dir.exists(dir)) {
        stop("Incorrect stain directory.", call. = FALSE)
    }

    meta_file <- paste0(dir, ".stain/meta.json")

    if (!file.exists(meta_file)) {
        stop("Stain meta file doesn't exist.", call. = FALSE)
    }

    cat(jsonlite::toJSON(meta, pretty = TRUE, auto_unbox = TRUE),
        file = meta_file)
}


#' Set the id for the stain.
#'
#' @param dir The location of the \code{.stain/} directory.
#'
#' @param id A 64 character alphanumeric.
stain_meta_set_id <- function(dir, id) {
    meta <- stain_meta_read(dir)
    meta$id <- as.character(id)
    stain_meta_write(meta, dir)
}


#' Set the stain version.
#'
#' @param dir The location of the \code{.stain/} directory.
#'
#' @param stain_version The version of the Stain package.
stain_meta_set_stain_version <- function(dir, stain_version) {
    meta <- stain_meta_read(dir)
    meta$stain_version <- as.character(stain_version)
    stain_meta_write(meta, dir)
}


#' Set a sbatch option parameter.
#'
#' @param dir The location of the \code{.stain/} directory.
#'
#' @param opt The sbatch option key.
#'
#' @param param The value for the sbatch option.
stain_meta_set_sbatch_opt <- function(dir, opt, param) {
    meta <- stain_meta_read(dir)
    sbatch_options <- meta$sbatch_options

    if (is.null(sbatch_options)) {
        sbatch_options <- data.frame(
            option = opt,
            param = param
        )
    } else if (opt %in% sbatch_options$option) {
        row <- which(sbatch_options$option == opt)
        sbatch_options$param[row] <- param
    } else {
        sbatch_options <- rbind(sbatch_options, list(
            option = opt,
            param = param
        ))
    }

    meta$sbatch_options <- sbatch_options
    stain_meta_write(meta, dir)
}


#' Append a new submission history row.
#'
#' @param dir The location of the \code{.stain/} directory.
#'
#' @param job_id The slurm job identifier.
#'
#' @param sub_date The submission date for the corresponding slurm job. Default
#' value is \code{Sys.time()}.
stain_meta_sub_history_append <- function(dir, job_id,
                                          sub_date = as.character(Sys.time())) {
    meta <- stain_meta_read(dir)
    submission_history <- meta$submission_history

    if (is.null(submission_history)) {
        submission_history <- data.frame(
            job_id = job_id,
            submission_date = sub_date
        )
    } else {
        submission_history <- rbind(submission_history, list(
            job_id = job_id,
            submission_date = sub_date
        ))
    }

    meta$submission_history <- submission_history
    stain_meta_write(meta, dir)
}
