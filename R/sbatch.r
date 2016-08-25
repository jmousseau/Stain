#' Create an SBATCH option
#'
#' @param key The key for the sbatch option.
#'
#' @return A function that takes a single argument representing
#' the value for the \code{key}.
sbatch_opt <- function(key) {
    return(function(value) {
        return(paste0("--", key, "=", value))
    })
}



#' A list of sbatch options.
#'
#' The value of each item in the list is a string or a function
#' which takes a string as a parameter, using \code{sbatch_opt}.
#'
#' @export
sbatch_opts <- list (
    begin = sbatch_opt("begin"),
    cpus_per_task = sbatch_opt("cpus-per-task"),
    mail_type = sbatch_opt("mail-type"),
    mail_user = sbatch_opt("mail-user"),
    memory = sbatch_opt("mem"),
    nodes = sbatch_opt("nodes"),
    ouput = sbatch_opt("ouput"),
    time = sbatch_opt("time")
)
