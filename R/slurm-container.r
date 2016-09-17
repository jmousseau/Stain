#' SlurmContainer R6 object.
#'
#' A slurm container is simply a directory with a specific
#' structure, particulary it has a submit.slurm script at the
#' top level.
#'
#' @export
Stain <- R6::R6Class("SlurmContainer",
    public = list(
        dir = NULL,
        globals = list(),
        initialize = function(dir = ".", options = c()) {
            private$options <- SlurmOptions$new(options)

            sub_dirs <- c("data", "sources", "objects")
            stain_dir <- paste0(dir, ".stain")

            is_stain <- Reduce("&", sub_dirs %in% sapply(list.dirs(stain_dir), basename))
            if (is_stain && dir.exists(stain_dir)) {
                self$dir <- dir
                private$update_globals()
            } else {
                name <- paste0("job_", private$rand_alphanumeric())
                dir <- paste(getwd(), dir, name, sep = "/")
                self$dir <- dir

                for (sub_dir in sub_dirs) {
                    dir.create(paste(dir, ".stain", sub_dir, sep = "/"),
                               recursive = TRUE, showWarnings = FALSE)
                }

                dir.create(paste0(dir, "/output"), recursive = TRUE,
                            showWarnings = FALSE)
                script <- SlurmBashScript$new(dir, private$options)
            }
        },
        save_globals = function() {
            private$clean_object_files()

            for (name in names(self$globals)) {
                private$add_object(name, self$globals[[name]])
            }
        },
        remove_objects = function(names) {
            private$remove_files(paste0(names, ".RData"), "objects")
        },
        add_sources = function(files) {
            private$add_files(files, "sources")
            stain_message_source_files(self$get_files(TRUE)$sources)
        },
        remove_sources = function(basenames) {
            private$remove_files(basenames, "sources")
            stain_message_source_files(self$get_files(TRUE)$sources)
        },
        add_data = function(files) {
            private$add_files(files, "data")
        },
        remove_data = function(basenames) {
            private$remove_files(basenames, "data")
        },
        delete = function(confirmation = FALSE) {
            if (confirmation) {
                system(paste("rm -rf", self$dir))
            } else {
                warning("Container not deleted becaue TRUE must be passed to `delete`.")
            }
        },
        get_files = function(full.names = FALSE) {
            return(list(
                data = list.files(paste(self$dir, ".stain", "data", sep = "/"),
                                  full.names = full.names),
                objects = list.files(paste(self$dir, ".stain", "objects", sep = "/"),
                                     full.names = full.names),
                sources = list.files(paste(self$dir, ".stain", "sources", sep = "/"),
                                     full.names = full.names)
            ))
        },
        submit = function(user, host, submit_dir) {
            stain_scp(user, host, self$dir, submit_dir)

            job_dir <- paste(submit_dir, self$dir, sep = "/")
            submit_cmd <- paste("cd", job_dir, "&& sbatch submit.slurm")
            stain_ssh(user, host, submit_cmd)
        }
    ),
    private = list(
        options = NULL,
        add_files = function(files, stain_sub_dir) {
            dir <- paste(self$dir, ".stain", stain_sub_dir, sep = "/")

            for (file in files) {
                if (!file.exists(file)) { stop("File does not exist. Copy aborted.") }
            }

            for (file in files) {
                file.copy(file, paste(dir, basename(file), sep = "/"), overwrite = TRUE)
            }

            private$update_globals()
        },
        remove_files = function(files, stain_sub_dir) {
            for (file in files) {
                if (!file.exists(file)) { stop("File does not exist. Removal aborted.") }
            }

            for (file in files) {
                file <- paste(self$dir, ".stain", stain_sub_dir, file, sep = "/")
                file.remove(file)
            }

            private$update_globals()
        },
        add_object = function(name, value) {
            if (length(value) > 1) {
                is_na <- FALSE
            } else {
                is_na <- is.na(value)
            }

            if (!is_na) {
                obj_dir <- paste0(self$dir, "/.stain/objects")
                rdata <- paste0(name, ".Rdata")
                e <- new.env()
                e[[name]] <- value
                save(list = name, envir = e, file = paste(obj_dir, rdata, sep = "/"))
            } else {
                stop("Object must have an non NA value.")
            }

            private$update_globals()
        },
        clean_object_files = function() {
            object_files <- list.files(paste0(self$dir, ".stain/objects"), full.names = TRUE)

            for (object_file in object_files) {
                file.remove(object_file)
            }
        },
        update_globals = function() {
            source_files <- list.files(paste0(self$dir, "/.stain/sources"), full.names = TRUE)
            object_files <- list.files(paste0(self$dir, "/.stain/objects"), full.names = TRUE)

            globals <- find_globals(source_files)

            # Check for the globals in the object files
            e <- new.env()
            for (object_file in object_files) {
                load(object_file, envir = e)
                name <- strsplit(basename(object_file), "[.]")[[1]][1]
                if (name %in% names(e) && (name %in% names(globals) || length(globals) == 0)) {
                    globals[[name]] <- e[[name]]
                }
            }

            # Copy over existing global values
            for (name in names(self$globals)) {
                if (name %in% names(globals)) {
                    globals[[name]] <- self$globals[[name]]
                }
            }

            # Display helpful message to the user
            stain_message_globals(globals)

            self$globals <- globals
        },
        rand_alphanumeric = function(len = 3) {
            population <- c(rep(0:9, each = 5), LETTERS, letters)
            samp <- sample(population, len, replace = TRUE)
            return(paste(samp, collapse = ''))
        }
    )
)
