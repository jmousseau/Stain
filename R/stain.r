#' Create a new slurm container.
#'
#' IMPORTANT: To call this function use \code{Stain$new}.
#'
#' @param main An R source file containing a \code{main()} function.
#'
#' @param location The directory where to create the slurm container. The
#' default location is the current working directory.
#'
#' @param source_files R source files other than \code{main}.
#'
#' @param settings A \code{SlurmSettings} object.
#'
#' @return A \code{SlurmJob} object.
#'
#' @export
stain_new <- function(main, location = ".", source_files = list(),
                      settings = SlurmSettings$new()) {
    return(SlurmJob$new(main, location, source_files, settings))
}
