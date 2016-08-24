#' SlurmSettings R6 object.
#'
#' An interface to SBATCH settings.
#'
#' @export
SlurmSettings <- R6::R6Class("SlurmSettings",
    public = list(
        nodes = NA,
        cpus_per_task = NA,
        time = NA,
        memory = NA,
        initialize = function(nodes = 1, cpus_per_task = 12,
                              time = "00:30:00", memory = "16g") {
            self$nodes <- nodes
            self$cpus_per_task <- cpus_per_task
            self$time <- time
            self$memory <- memory
        },
        sbatch_comments = function() {
            sb <- "#SBATCH --"
            sb_nodes <- paste0(sb, "nodes=", self$nodes)
            sb_cpus_per_task <- paste0(sb, "cpus-per-task=",
                                       self$cpus_per_task)
            sb_time <- paste0(sb, "time=", self$time)
            sb_memory <- paste0(sb, "mem=", self$memory)
            return(paste(sb_nodes, sb_cpus_per_task, sb_time,
                         sb_memory, "#SBATCH -o R_job.o%j", sep = "\n"))
        }
    )
)
