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


#' Test sbatch options for equality.
#'
#' sbatch option equallity is achieved if the keys of the options
#' are the same.
#'
#' @param opt_1 An sbatch option string.
#'
#' @param opt_2 An sbatch option string.
#'
#' @return A boolean value.
sbatch_opts_equal <- function(opt_1, opt_2) {
    return(sbatch_opt_key(opt_1) == sbatch_opt_key(opt_2))
}


#' Insert an sbatch option into a set.
#'
#' @param opt The sbatch option to insert
#'
#' @param opts A set of sbatch options. Default value is the empty
#' set.
#'
#' @return A set with \code{opt} inserted.
sbatch_opts_insert <- function(opt, opts = c()) {
    did_set <- FALSE

    for (i in 1:length(opts)) {
        if (sbatch_opts_equal(opt, opts[i])) {
            opts[i] = opt
            did_set = TRUE
        }
    }

    if(!did_set) {
        opts <- c(opts, opt)
    }

    return(opts)
}


#' Get the key of an sbatch.
#'
#' @param opt An sbatch option string.
#'
#' @return The \code{opt}'s key.
sbatch_opt_key <- function(opt) {
    return(strsplit(opt, "=")[[1]][1])
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
sbatch_mail_type_opts <- list(
    all = sbatch_opt("mail-type")("ALL"),
    begin = sbatch_opt("mail-type")("BEGIN"),
    end = sbatch_opt("mail-type")("END"),
    fail = sbatch_opt("mail-type")("FAIL"),
    none = sbatch_opt("mail-type")("NONE"),
    requeue = sbatch_opt("mail-type")("REQUEUE"),
    stage_out = sbatch_opt("mail-type")("STAGE_OUT"),
    time_limit = sbatch_opt("mail-type")("TIME_LIMIT"),
    time_limit_90 = sbatch_opt("mail-type")("TIME_LIMIT_90"),
    time_limit_80 = sbatch_opt("mail-type")("TIME_LIMIT_80"),
    time_limit_50 = sbatch_opt("mail-type")("TIME_LIMIT_50")
)
