#' NOAARequest R6 object.
#'
#' An interface to SLURM bash scripts and their submissions.
SlurmJob <- R6::R6Class("SlurmJob",
    public = list(
        main_file = NULL,
        params = list(),
        initialize = function(main_file, source_files = list()) {
            if (!missing(main_file)) {
                self$main_file <- main_file
                private$source_files = source_files

                private$find_globals()
            } else {
                stop("A file containing a main() function must be provided.")
            }
        }
    ),
    private = list(
        globals = list(),
        source_files = list(),
        find_globals = function() {
            e <- new.env()
            source_file(self$main_file, e)

            for (file in private$source_files) {
                source_file(file, e)
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
                message(paste("Found", nglobals, "parameter to specify."))
                message("Access these variables in the `params` property.")
                message("If new source files are added, `params` will be updated.")
            }

            private$globals = globals
            self$params = globals
        }
    )
)
