#' SlurmOptions R6 object.
#'
#' An interface to SBATCH settings.
SlurmOptions <- R6::R6Class("SlurmOptions",
    public = list(
        options = c(sbatch_opts$nodes(1),
                    sbatch_opts$memory("8g"),
                    sbatch_opts$cpus_per_task(1),
                    sbatch_opts$time("00:30:00")),
        initialize = function(options = c()) {
            for (opt in options) {
                self$options <- sbatch_opts_insert(opt, self$options)
            }
        },
        for_slurm_script = function() {
            comments <- "#!/bin/bash"

            for (opt in self$options) {
                comments <- paste(comments, paste("#SBATCH", opt), sep = "\n")
            }

            return(comments)
        }
    )
)
