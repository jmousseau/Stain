#' SlurmContainer R6 object.
#'
#' A slurm container is simply a directory with a specific
#' structure, particulary it has a submit.slurm script at the
#' top level.
SlurmContainer <- R6::R6Class("SlurmContainer",
    public = list(
        dir = NULL,
        globals = list(),
        initialize = function(dir = ".") {
            self$dir <- dir

            sub_dirs <- c("data", "sources", "objects")
            stain_dir <- paste0(dir, ".stain")

            if (!dir.exists(stain_dir)) {
                return()
            }

            is_stain <- Reduce("&", sub_dirs %in% sapply(list.dirs(stain_dir), basename))
            if (!is_stain) {
                name <- paste0("job_", private$rand_alphanumeric())
                dir <- paste(getwd(), dir, name, sep = "/")

                for (sub_dir in sub_dirs) {
                    dir.create(paste(dir, ".stain", sub_dir, sep = "/"),
                               recursive = TRUE, showWarnings = FALSE)
                }

                dir.create(paste0(dir, "/output"), recursive = TRUE,
                            showWarnings = FALSE)
            }
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
        },
        remove_objects = function(names) {
            private$remove_files(paste0(names, ".RData"), "objects")
        },
        add_sources = function(files) {
            private$add_files(files, "sources")
        },
        remove_sources = function(basenames) {
            private$remove_files(basenames, "sources")
        },
        add_data = function(files) {
            private$add_files(files, "data")
        },
        remove_data = function(basenames) {
            private$remove_files(basenames, "data")
        },
        get_files = function() {
            return(list(
                data = list.files(paste(self$dir, ".stain", "data", sep = "/")),
                objects = list.files(paste(self$dir, ".stain", "objects", sep = "/")),
                sources = list.files(paste(self$dir, ".stain", "sources", sep = "/"))
            ))
        }
    ),
    private = list(
        add_files = function(files, stain_sub_dir) {
            dir <- paste(self$dir, ".stain", stain_sub_dir, sep = "/")

            for (file in files) {
                if (!file.exists(file)) { stop("File does not exist. Copy aborted.") }
            }

            for (file in files) {
                file.copy(file, dir, recursive = TRUE)
            }
        },
        remove_files = function(files, stain_sub_dir) {
            for (file in files) {
                if (!file.exists(file)) { stop("File does not exist. Removal aborted.") }
            }

            for (file in files) {
                file <- paste(self$dir, ".stain", stain_sub_dir, file, sep = "/")
                file.remove(file)
            }
        },
        rand_alphanumeric = function(len = 3) {
            population <- c(rep(0:9, each = 5), LETTERS, letters)
            samp <- sample(population, len, replace = TRUE)
            return(paste(samp, collapse = ''))
        }
    )
)
