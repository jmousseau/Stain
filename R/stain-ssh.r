#' ssh with the Stain RSA key.
#'
#' The stain-specific key must be used to ensure remote login.
#'
#' @param user The user on your remote host.
#'
#' @param host The static ip address or url for the remote host.
#'
#' @param cmds A sting of one or more commands to run on the remote host.
stain_ssh <- function(user, host, cmds = "") {
    if (!stain_ssh_key_exists()) {
        invisible(stain_ssh_key_gen())
    }

    remote_host <- paste(user, host, sep = "@")
    system(paste("ssh", remote_host, "-t -t -i ~/.ssh/stain_rsa",
                 paste0("\"", cmds, "\"")))
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
        write.table(cmd, file = pipe("pbcopy"), sep = "\t",
                    col.names = F, row.names = F , quote = F)
    } else {
        cat("Run the following bash command in your terminal to setup remote submission:")
        cat(cmd)
    }
}
