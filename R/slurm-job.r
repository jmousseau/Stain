#' NOAARequest R6 object.
#'
#' An interface to SLURM bash scripts and their submissions.
SlurmJob <- R6::R6Class("SlurmJob",
    public = list(
        main_file = NULL,
        initialize = function(main_file) {
            if (!missing(main_file)) {
                self$main_file <- main_file
            } else {
                stop("A file containing a main() function must be provided.")
            }
        }
    )
)
