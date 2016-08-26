#' SlurmJob R6 object.
#'
#' An interface to SLURM bash scripts and their submissions.
#'
#' @export
SlurmJob <- R6::R6Class("SlurmJob",
    public = list(
        params = list(),
        main_file = NULL,
        input_files = list(),
        source_files = list(),
        initialize = function(main_file, container_location = ".",
                              source_files = list(),
                              settings = SlurmSettings$new()) {
            if (!missing(main_file)) {
                self$main_file <- main_file

                self$source_files <- source_files

                private$base_dir <- container_location
                private$find_globals()
                private$settings <- settings
            } else {
                stop("A file containing a main() function must be provided.")
            }
        },
        create = function(allow_creation_without_input_files = FALSE) {

            if (!allow_creation_without_input_files && length(self$input_files) == 0) {
                stop("Attempting to create slurm job without `input_files`. Pass TRUE to `create` to override.")
            }

            container <- SlurmContainer$new(private$base_dir)

            tryCatch({
                for (name in names(self$params)) {
                    container$add_object(name, self$params[[name]])
                }

                for (file in c(self$source_files, self$main_file)) {
                    container$add_source(file)
                }

                for (file in self$input_files) {
                    container$add_input(file)
                }
            }, error = function(e) {
                system(paste("rm -rf", container$dir))
                stop(e)
            })

            script <- SlurmBashScript$new(container, self$main_file, private$settings)
        }
    ),
    private = list(
        globals = list(),
        base_dir = ".",
        settings = NA,
        find_globals = function() {
            e <- new.env()
            testthat::source_file(self$main_file, e)

            for (file in self$source_files) {
                testthat::source_file(file, e)
            }

            globals <- codetools::findGlobals(e$main)

            # Filter known `findGlobals` errors
            known_errors <- c("{", "}", "::")
            globals <- globals[!(globals %in% known_errors)]

            # Filter all functions in loaded packages
            for (package in (.packages())) {
                package <- paste0("package:", package)
                exports <- names(as.list(as.environment(package)))
                globals <- globals[!(globals %in% exports)]
            }

            # Filter functions and variables in source files
            globals <- globals[!(globals %in% names(as.list(e)))]

            nglobals <- length(globals)

            if (nglobals > 0) {
                if (nglobals == 1) {
                    vars <- "var"
                    t_vars <- "this var"
                } else {
                    vars <- "vars"
                    t_vars <- "these vars"
                }

                cat(paste("Found", nglobals, vars, "to specify:"))
                for (global in globals) {
                    cat(paste("\n    -", global))
                }

                cat(paste("\n\nSet", t_vars, "in the `params` property of your `SlurmJob` instance."))
            }

            # Set the values of all gobals to NA
            global_list <- list()

            for (global in globals) {
                global_list[[global]] <- NA
            }

            private$globals = global_list
            self$params = global_list
        }
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


