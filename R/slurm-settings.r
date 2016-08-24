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
        mail_to = NA,
        mail_type = NA,
        initialize = function(nodes = 1, cpus_per_task = 12,
                              time = "00:30:00", memory = "16g",
                              mail_to = NA, mail_type = "all") {
            self$nodes <- nodes
            self$cpus_per_task <- cpus_per_task
            self$time <- time
            self$memory <- memory

            if (!is.na(self$mail_to) && !is.na(self$mail_type)) {
                self$mail_to <- mail_to
                self$mail_type <- mail_type
            }
        },
        sbatch_comments = function() {
            sb <- "#SBATCH --"
            sb_nodes <- paste0(sb, "nodes=", self$nodes)
            sb_cpus_per_task <- paste0(sb, "cpus-per-task=",
                                       self$cpus_per_task)
            sb_time <- paste0(sb, "time=", self$time)
            sb_memory <- paste0(sb, "mem=", self$memory)

            comments <- paste(sb_nodes, sb_cpus_per_task, sb_time,
                              sb_memory, "#SBATCH -o R_job.o%j", sep = "\n")

            if (!is.na(self$mail_to)) {
                sb_mail_to <- paste0(sb, "mail-user=", self$mail_to)
                sb_mail_type <- paste0(sb, "mail-type=", self$mail_type)

                comments <- paste(comments, sb_mail_type, sb_mail_to, sep = "\n")
            }

            return(commments)
        }
    )
)
