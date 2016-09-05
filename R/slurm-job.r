#' SlurmJob R6 object.
#'
#' A wrapper around SlurmContainer objects.
SlurmJob <- R6::R6Class("SlurmJob",
    public = list(
        params = list(),
        main_file = NULL,
        data_files = list(),
        source_files = list(),
        initialize = function(main_file, container_location = ".",
                              source_files = list(),
                              settings = SlurmSettings$new()) {
            if (!missing(main_file)) {
                self$main_file <- main_file

                self$source_files <- source_files

                private$base_dir <- container_location
                globals <- find_globals(c(main_file, source_files))
                self$params <- globals
                private$globals <- globals
                private$settings <- settings
            } else {
                stop("A file containing a main() function must be provided.")
            }
        },
        create = function(allow_creation_without_data_files = FALSE) {

            if (!allow_creation_without_data_files && length(self$data_files) == 0) {
                stop("Attempting to create slurm job without `data_files`. Pass TRUE to `create` to override.")
            }

            container <- SlurmContainer$new(private$base_dir)

            tryCatch({
                for (name in names(self$params)) {
                    container$add_object(name, self$params[[name]])
                }

                container$add_sources(c(self$source_files, self$main_file))
                container$add_data(self$data_files)
            }, error = function(e) {
                container$delete(TRUE)
                stop(e)
            })

            script <- SlurmBashScript$new(container, private$settings)
        }
    ),
    private = list(
        globals = list(),
        base_dir = ".",
        settings = NA
    )
)


#' Submit one or more slurm jobs.
#'
#' This function will submit your slurm job given the path
#' to a slurm container.
#'
#' @param jobs The \code{job_<alphanumeric>/} directories for
#' the slurm container. May also
#'
#' @export
submit_jobs <- function(jobs) {
    wd <- getwd()

    for (dir in jobs) {
        tryCatch({
            setwd(dir)
            system("sh submit.sh")
        }, error = function(e) {
            setwd(wd)
            stop(e)
        })

    }

    setwd(wd)
}


