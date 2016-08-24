#' SlurmJob R6 object.
#'
#' An interface to SLURM bash scripts and their submissions.
SlurmJob <- R6::R6Class("SlurmJob",
    public = list(
        params = list(),
        main_file = NULL,
        input_files = list(),
        source_files = list(),
        initialize = function(main_file, container_location = ".", source_files = list()) {
            if (!missing(main_file)) {
                self$main_file <- main_file

                self$source_files <- source_files

                private$base_dir <- container_location
                private$find_globals()
            } else {
                stop("A file containing a main() function must be provided.")
            }
        },
        create = function() {
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

            script <- SlurmBashScript$new(container, self$main_file)
        }
    ),
    private = list(
        globals = list(),
        base_dir = ".",
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
                message(paste("Found", nglobals, "parameter to specify:"))
                message(globals)
                message("Access these variables in the `params` property.")
                message("If new source files are added, `params` will be updated.")
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
