#' ssh with the Stain RSA key.
#'
#' The stain-specific key must be used to ensure remote login.
#'
#' @param user The user on your remote host.
#'
#' @param host The static ip address or url for the remote host.
#'
#' @param cmds A sting of one or more commands to run on the remote host.
#'
#' @param intern Indicates whether to capture the output of the command
#' as an R character vector.
#'
stain_ssh <- function(user, host, cmds = "", intern = FALSE) {
    if (is.null(user) | is.null(host)) {
        stop("No user or host specified.", call. = FALSE)
    }

    if (!stain_ssh_key_exists()) {
        invisible(stain_ssh_key_gen())
    }

    remote_host <- paste(user, host, sep = "@")
    system(paste("ssh", remote_host, "-t -t -i ~/.ssh/stain_rsa",
                 paste0("\"", cmds, "\"")),
           intern = intern)
}


#' scp with the Stain RSA key.
#'
#' The stain-specific key must be used to ensure remote login.
#'
#' @param from The directory or file to copy.
#'
#' @param to The destination.
stain_scp <- function(from, to) {
    system(paste("scp -i ~/.ssh/stain_rsa -r", from, to))
}


#' Get squeue info on certain jobs.
#'
#' @param user The user on your remote host.
#'
#' @param host The static ip address or url for the remote host.
#'
#' @param job_ids A collection of job ids for which to fetch statuses.
#'
#' @return A data frame with columns corresponding to those produced
#' by the \code{squeue -l} command.
stain_ssh_squeue <- function(user, host, job_ids) {
    job_ids <- paste(job_ids, collapse = ",")
    remote_host <- paste(user, host, sep = "@")

    squeue_cmd <- paste("squeue -l -j", job_ids)
    output <- stain_ssh(user, host, squeue_cmd, intern = TRUE)

    output_table <- sapply(output, USE.NAMES = FALSE, function(row) {
        tokens <- strsplit(row, " ")[[1]]
        return(tokens[tokens != ""])
    })

    csv_header <- paste(output_table[[2]], collapse = "\t")
    csv_header <-  gsub("[\r]", "", csv_header)

    if (length(output_table) > 2) {
        csv_body <- paste(lapply(output_table[3:length(output_table)], function(row) {
            row <- paste(row, collapse = "\t")
            row <-  gsub("[\r]", "", row)
            return(row)
        }), collapse = "\n")
        csv <- paste(csv_header, csv_body, sep = "\n")
    } else {
        csv <- csv_header
    }

    state_table <- utils::read.delim(textConnection(csv))

    return(state_table)
}


#' Get sacct info on certain jobs.
#'
#' @param user The user on your remote host.
#'
#' @param host The static ip address or url for the remote host.
#'
#' @param job_ids A collection of job ids for which to fetch statuses.
#'
#' @return A data frame with columns corresponding to those produced
#' by the \code{sacct --brief --jobs} command.
stain_ssh_sacct <- function(user, host, job_ids) {
    job_ids <- paste(job_ids, collapse = ",")
    remote_host <- paste(user, host, sep = "@")

    sacct_cmd <- paste("sacct --brief --jobs", job_ids)
    output <- stain_ssh(user, host, sacct_cmd, intern = TRUE)
    output[2] <- NA
    output <- output[!is.na(output)]

    output_table <- t(sapply(output, USE.NAMES = FALSE, function(row) {
        tokens <- strsplit(row, " ")[[1]]
        return(tokens[tokens != "" & tokens != "\r"])
    }))

    csv_header <- output_table[1, ]
    csv_body <- output_table[-1, ]
    state_table <- as.data.frame(csv_body)

    if (nrow(state_table) > 0) {
        colnames(state_table) <- csv_header
        state_table <- state_table[seq(1, length(state_table[, 1]), by = 2), ]
    }

    return(state_table)
}


#' Check for a Stain ssh key.
#'
#' @return If a public/private key pair exists in \code{~/.ssh/} with the name
#' \code{stain_rsa}, return TRUE, otherwise return FALSE.
stain_ssh_key_exists <- function() {
    return("stain_rsa" %in% list.files("~/.ssh/"))
}


#' Generate a Stain ssh key.
#'
#' A 4096 bit key will be generated and stored in \code{~/.ssh/} with the name
#' \code{stain_rsa}.
#'
#' @param overwrite Should an existing Stain ssh key be overwritten. Default
#' value is FALSE.
stain_ssh_key_gen <- function(overwrite = FALSE) {
    if (overwrite | !(overwrite | stain_ssh_key_exists())) {
        system("ssh-keygen -b 4096 -f ~/.ssh/stain_rsa -N ''")
    }
}


#' Create bash code for ssh setup.
#'
#' In order for a remote submission to work, an ssh public key for Stain must
#' be present in the remote host's \code{~/.ssh/authorized_keys} list. This
#' process requires two steps. 1) To \code{scp} the public key and 2) to add
#' the key to \code{~/.ssh/authorized_keys}. This function will autogenerate
#' the necessary bash code to complete these steps.
#'
#' @param user The user on your remote host.
#'
#' @param host The static ip address or url for the remote host.
#'
#' @return A single bash command to run.
#'
#' @export
stain_ssh_setup <- function(user, host) {
    remote_host <- paste(user, host, sep = "@")
    scp <- paste0("scp ~/.ssh/stain_rsa.pub", remote_host, ":~/.ssh/stain_rsa.pub")
    ssh <- paste0("ssh ", scp, " 'echo `cat ~/.ssh/stain_rsa.pub` >> ~/.ssh/authorized_keys'")
    cmd <- paste0(scp, " && ", ssh)

    if (Sys.info()["sysname"] == "Darwin") {
        cat("The bash command to setup remote submission has been copied to your clipboard. Run it in your terminal.")
        utils::write.table(cmd, file = pipe("pbcopy"), sep = "\t",
                           col.names = F, row.names = F , quote = F)
    } else {
        cat("Run the following bash command in your terminal to setup remote submission:")
        cat(cmd)
    }
}
