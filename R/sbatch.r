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
    key <- strsplit(opt, "=")[[1]][1]
    return(substr(key, 3, nchar(key)))
}


#' Get the value of an sbatch option.
#'
#' @param opt An sbatch option string.
#'
#' @return The \code{opt}'s value.
sbatch_opt_value <- function(opt) {
    return(strsplit(opt, "=")[[1]][2])
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
    output = sbatch_opt("output"),
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


#' Create single sbatch mail type key value pair.
#'
#' A user may specific multiple \code{sbatch_mail_type_opts},
#' which must be combined into a single key value pair that
#' contains the options seperated by commas.
#'
#' @param opts A list of sbatch mail type options.
sbatch_mail_type_combine <- function(opts) {
    opt_keys <- sapply(opts, sbatch_opt_key, USE.NAMES = FALSE)
    mail_type_opts <- which(opt_keys == "--mail-type")

    mail_type_opt_vals <- sapply(opts[mail_type_opts], sbatch_opt_value,
                                 USE.NAMES = FALSE)
    mail_type_opt_val <- paste(unique(mail_type_opt_vals), collapse = ",")
    mail_type_opt <- sbatch_opt("mail-type")(mail_type_opt_val)

    return(c(opts[-mail_type_opts], mail_type_opt))
}


#' Fill in dependency list placeholders.
#'
#' The placeholders \code{PREVIOUS(ALL)} and \code{PREVIOUS(<n>)} can be used in
#' a sbatch dependency list and are replaced by all or n of the previous
#' submission job ids.
#'
#' @param dep_list The string dependency list value of the key-value pair
#' for a sbatch dependency list options.
#'
#' @param job_id_sub_history An array of job ids ordered oldest to newest.
#'
#' @return A dependency list with the proper job ids in the list.
sbatch_dependency_list <- function(dep_list, job_id_sub_history) {
    # Order from newest to oldest.
    job_id_sub_history <- rev(job_id_sub_history)

    if (length(job_id_sub_history) == 0) {
        return("")
    }

    regex <- "PREVIOUS[(]([1-9]+)[)]"
    to_replace <- stringr::str_match_all(dep_list, regex)[[1]]

    if (length(to_replace) > 0) {
        to_replace <- as.data.frame(to_replace)
        colnames(to_replace) <- c("regexp", "n")
        to_replace$n <- as.numeric(as.character(to_replace$n))
        to_replace$regexp <- as.character(to_replace$regexp)

        # Create a literal parentheses regex expression.
        to_replace$regexp <- sapply(to_replace$regexp, function(exp) {
            exp <- gsub("[(]", "[(]", exp)
            exp <- gsub("[)]", "[)]", exp)
            return(exp)
        })

        prev_n_jobs <- function(n) {
            job_ids <- job_id_sub_history[1:n]
            job_ids <- job_ids[!is.na(job_ids)]
            return(paste(job_ids, collapse = ":"))
        }

        to_replace$replacement <- sapply(to_replace$n, prev_n_jobs)

        for (i in length(to_replace$replacement)) {
            row <- to_replace[i, ]
            dep_list <- gsub(row$regexp, row$replacement, dep_list)
        }
    }

    regex <- "PREVIOUS[(]ALL[)]"
    dep_list <- gsub(regex, paste(job_id_sub_history, collapse = ":"), dep_list)

    return(dep_list)
}
