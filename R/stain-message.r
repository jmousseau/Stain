#' Message for globals.
#'
#' Prompt the user to set globals if they have not already been
#' specified.
#'
#' @param globals The list of globals for a stain.
stain_message_globals <- function(globals) {
    na_globals <- sapply(globals, is.na)
    n_globals <- length(na_globals)

    if (n_globals != 0) {
        na <- globals[na_globals]

        if (n_globals == 1) {
            plurality <- "global"
            demonstrative <- paste("this", plurality)
        } else {
            plurality <- "globals"
            demonstrative <- paste("these", plurality)
        }

        cat(paste(length(na_globals), plurality, "to specify:"))

        for (global in names(na_globals)) {
            cat(paste("\n    -", global))
        }

        cat(paste("\n\nSet", demonstrative, "in the `globals` property of your `Stain` instance."))
    }
}


#' Message for source files.
#'
#' One of the source files must contain a \code{main} function and this
#' message will notify the user if none of his or her source files
#' contain a \code{main} function.
#'
#' @param source_files The list of R source files.
stain_message_source_files <- function(source_files) {
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

            cat(paste(plurality, "contain a `main()` function."))
        }
    } else {
        cat("A `Stain` object must contain at least one source file.")
    }
}


#' Message for ssh.
#'
#' Notify the user about remote host ssh requirements.
stain_message_ssh <- function() {
    cat("If your cluster is remote, add the .ssh/stain_rsa.pub key to your remote host. ")
    cat("To autogenerate the bash code, see ?stain_ssh_setup.")
}
