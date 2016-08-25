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
#' To ensure proper formatting, the \code{mail_type} option should
#' be set using \code{sbatch_mail_types}. Multiple mail types need
#' to be comma seperated.
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


#' A list of sbatch mail types.
#'
#' The value of each item in the list is a string representing
#' a mail type option.
#'
#' @export
sbatch_mail_types <- list(
    all = "ALL",
    begin = "BEGIN",
    end = "END",
    fail = "FAIL",
    none = "NONE",
    requeue = "REQUEUE",
    stage_out = "STAGE_OUT",
    time_limit = "TIME_LIMIT",
    time_limit_90 = "TIME_LIMIT_90",
    time_limit_80 = "TIME_LIMIT_80",
    time_limit_50 = "TIME_LIMIT_50"
)
