#' Message for globals.
#'
#' Prompt the user to set globals if they have not already been
#' specified.
#'
#' @param globals The list of globals for a stain.
#'
#' @param is_submitting Is a slurm job being submitted? Default
#' value is FALSE to avoid any fatal errors.
stain_message_globals <- function(globals, is_submitting = FALSE) {
    na_globals <- globals[sapply(globals, is.na)]
    n_globals <- length(na_globals)

    if (n_globals > 0) {
        if (n_globals == 1) {
            plurality <- "global"
            demonstrative <- paste("this", plurality)
        } else {
            plurality <- "globals"
            demonstrative <- paste("these", plurality)
        }

        message(paste(length(na_globals), plurality, "to specify:"))

        for (global in names(na_globals)) {
            message(paste("\n    -", global))
        }

        message(paste("\nSet", demonstrative, "in the `globals` property of your `Stain` instance.\n"))

        if (is_submitting) {
            stop("Aborting submission.")
        }
    }
}


#' Message for source files.
#'
#' One of the source files must contain a \code{main} function and this
#' message will notify the user if none of his or her source files
#' contain a \code{main} function.
#'
#' @param source_files The list of R source files.
#'
#' @param is_submitting Is a slurm job being submitted? Default
#' value is FALSE to avoid any fatal errors.
stain_message_source_files <- function(source_files, is_submitting = FALSE) {
    file_count <- length(source_files)

    if (file_count > 0) {
        e <- new.env()

        for (file in source_files) {
            testthat::source_file(file, e)
        }

        if (is.null(e$main)) {
            if (file_count == 1) {
                plurality = paste("Your R source file doesn't")
            } else {
                plurality = paste("None of your", file_count, "R source files")
            }

            message(paste(plurality, "contain a `main()` function."))

            if (is_submitting) {
                stop("Aborting submission.")
            }
        }
    } else {
        message("A `Stain` object must contain at least one source file.")

        if (is_submitting) {
            stop("Aborting submission.")
        }
    }
}


#' Message for ssh.
#'
#' Notify the user about remote host ssh requirements.
stain_message_ssh <- function() {
    cat("If your cluster is remote, add the .ssh/stain_rsa.pub key to your remote host. ")
    cat("To autogenerate the bash code, see ?stain_ssh_setup.")
}
