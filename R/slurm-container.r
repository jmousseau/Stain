#' SlurmContainer R6 object.
#'
#' A slurm container is simply a directory with a specific
#' structure, particulary it has a submit.slurm script at the
#' top level.
SlurmContainer <- R6::R6Class("SlurmContainer",
    public = list(
        dir = NULL,
        initialize = function(dir = ".") {
            name <- paste0("job_", private$rand_alphanumeric())
            dir <- paste(getwd(), dir, name, sep = "/")
            self$dir <- dir

            for (sub_dir in c("/input", "/output", "/sources", "/.objects")) {
                dir.create(paste0(dir, sub_dir), recursive = TRUE,
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
                obj_dir <- paste0(self$dir, "/.objects")
                rdata <- paste0(name, ".Rdata")
                e <- new.env()
                e[[name]] <- value
                save(list = name, envir = e, file = paste(obj_dir, rdata, sep = "/"))
            } else {
                stop("Object must have an non NA value.")
            }
        },
        add_source = function(file) {
            if (file.exists(file)) {
                source_dir <- paste0(self$dir, "/sources")
                destination <- paste0(source_dir, paste0("/cp_of_", basename(file)))
                system(paste("cp -r", file, destination))
            } else {
                stop("Source file does not exist.")
            }
        },
        add_input = function(file) {
            if (file.exists(file)) {
                input_dir <- paste0(self$dir, "/input")
                destination <- paste0(input_dir, paste0("/cp_of_", basename(file)))
                system(paste("cp -r", file, destination))
            } else {
                stop("Source file does not exist.")
            }
        }
    ),
    private = list(
        rand_alphanumeric = function(len = 3) {
            population <- c(rep(0:9, each = 5), LETTERS, letters)
            samp <- sample(population, len, replace = TRUE)
            return(paste(samp, collapse = ''))
        }
    )
)
