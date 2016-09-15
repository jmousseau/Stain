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
