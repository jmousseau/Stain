#' Create a new slurm container.
#'
#' @param location The directory where to create the slurm container. The
#' default location is the current working directory.
#'
#' @param source_files R source files.
#'
#' @param settings A \code{SlurmSettings} object.
#'
#' @return A \code{SlurmContainer} object.
#'
#' @export
stain_new <- function(location = ".", source_files = list(),
                      settings = SlurmSettings$new()) {

    stain <- SlurmContainer$new(location, settings)

    tryCatch({
        stain$add_sources(source_files)
    }, error = function(e) {
        stain$delete(TRUE)
        stop(e)
    })

    return(stain)
}
