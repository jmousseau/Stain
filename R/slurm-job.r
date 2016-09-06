#' Submit one or more slurm jobs.
#'
#' This function will submit your slurm job given the path
#' to a slurm container.
#'
#' @param jobs The \code{job_<alphanumeric>/} directories for
#' the slurm container. May also
#'
#' @export
submit_jobs <- function(jobs) {
    wd <- getwd()

    for (dir in jobs) {
        tryCatch({
            setwd(dir)
            system("sbatch submit.slurm")
        }, error = function(e) {
            setwd(wd)
            stop(e)
        })

    }

    setwd(wd)
}
