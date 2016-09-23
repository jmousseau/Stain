#' Stain's submission history.
#'
#' @param dir The location of the \code{.stain/} directory.
#'
#' @return A data frame with \code{job_id} and \code{submission_date} columns,
#' both of type "character".
stain_sub_history <- function(dir) {
    sub_history_csv <- paste0(dir, "/.stain/submission_history.csv")
    sub_history_exists <- file.exists(sub_history_csv)

    if (sub_history_exists) {
        return(utils::read.csv(sub_history_csv, colClasses = c(
            "character", # job_id
            "character"  # submission_date
        )))
    } else {
        message("No submission history.")
    }
}


#' Append a job id to submission history.
#'
#' @param dir The location of the \code{.stain/} directory.
#'
#' @param job_id The slurm job identifier.
#'
#' @param sub_date The timestamp when the slurm job for the corresponding
#' \code{job_id} was submitted. Defaults to the system's current time.
stain_sub_history_append <- function(dir, job_id, sub_date = Sys.time()) {
    sub_history_csv <- paste0(dir, "/.stain/submission_history.csv")
    sub_history_exists <- file.exists(sub_history_csv)

    new_entry <- data.frame(
        job_id = as.character(job_id),
        submission_date = as.character(sub_date)
    )

    utils::write.table(new_entry, sub_history_csv,
                       append = sub_history_exists,
                       sep = ",", row.names = FALSE,
                       col.names = !sub_history_exists)
}
