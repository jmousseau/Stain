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
        system("ssh-keygen -b 4096 -f ~/.ssh/stain_rsa")
    }
}
