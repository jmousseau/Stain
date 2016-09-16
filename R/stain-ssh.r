#' Check for a Stain ssh key.
#'
#' @return If a public/private key pair exists in \code{~/.ssh/} with the name
#' \code{stain_rsa}, return TRUE, otherwise return FALSE.
stain_ssh_key_exists <- function() {
    return("stain_rsa" %in% list.files("~/.ssh/"))
}
