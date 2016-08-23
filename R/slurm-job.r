#' SlurmJob R6 object.
#'
#' An interface to SLURM bash scripts and their submissions.
SlurmJob <- R6::R6Class("SlurmJob",
    public = list(
        params = list(),
        input_files = list(),
        initialize = function(main_file, container_location = ".", source_files = list()) {
            if (!missing(main_file)) {
                private$main_file <- main_file

                for (file in source_files) {
                    if (!file.exists(file)) {
                        warning("Source file does not exist.")
                    }
                }

                private$source_files <- source_files
                private$base_dir <- container_location

                private$find_globals()
            } else {
                stop("A file containing a main() function must be provided.")
            }
        },
        add_input_files = function(files) {
            for (file in c(files)) {
                if (!file.exists(file)) {
                    warning("Input file does not exist.")
                }
            }

            input_files <- c(input_files, files)
        },
        create = function() {
            for (param in names(self$params)) {
                if (is.na(self$params[[param]])) {
                    message(paste0("`", param, "` "), appendLF = FALSE)
                    stop("is NA. Must be specified.")
                }
            }

            private$generate_container()
            objects_dir <- paste(private$base_dir, ".objects", sep = "/")

            for (param in names(self$params)) {
                value <- self$params[[param]]
                rdata <- paste(objects_dir, paste0(param, ".RData"), sep = "/")
                save(value, file = rdata)
            }

            # Copy source files to sources directory
            for (file in private$source_files) {
                cmd <- paste("cp -r", file, paste0(private$base_dir, "/sources"))
                system(cmd)
            }

            # Copy input files to input directory
            for (file in self$input_files) {
                cmd <- paste("cp -r", file, paste0(private$base_dir, "/input"))
                system(cmd)
            }
        }
    ),
    private = list(
        globals = list(),
        main_file = NULL,
        source_files = list(),
        base_dir = ".",
        find_globals = function() {
            e <- new.env()
            source_file(private$main_file, e)

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
        },
        generate_container = function() {
            private$base_dir <- paste0(private$base_dir, "/job")
            bd <- paste0(private$base_dir, "/")
            dir.create(paste0(bd, "input"), recursive = TRUE, showWarnings = FALSE)
            dir.create(paste0(bd, "output"), recursive = TRUE, showWarnings = FALSE)
            dir.create(paste0(bd, "sources"), recursive = TRUE, showWarnings = FALSE)
            dir.create(paste0(bd, ".objects"), recursive = TRUE, showWarnings = FALSE)

        }
    )
)
