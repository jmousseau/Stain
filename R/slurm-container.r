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

                script <- SlurmBashScript$new(dir, private$options)
            }
        },
        add_sources = function(files) {
            private$add_files(files, "sources")
            stain_message_source_files(self$list_files(TRUE)$sources,
                                       private$is_submitting)
        },
        remove_sources = function(basenames) {
            private$remove_files(basenames, "sources")
            stain_message_source_files(self$list_files(TRUE)$sources,
                                       private$is_submitting)
        },
        add_data = function(files) {
            private$add_files(files, "data")
        },
        remove_data = function(basenames) {
            private$remove_files(basenames, "data")
        },
        cancel = function(job_ids, user = private$user, host = private$host) {
            job_ids <- paste(job_ids, collapse = ",")

            stain_ssh(user, host, paste("scancel", job_ids))
        },
        delete = function(confirmation = FALSE) {
            if (confirmation) {
                system(paste("rm -rf", self$dir))

                for (obj_name in ls(envir = .GlobalEnv)) {
                    obj <- .GlobalEnv[[obj_name]]

                    if(class(obj)[1] == "SlurmContainer") {
                        if (self$dir == obj$dir) {
                            rm(list = obj_name, envir = .GlobalEnv)
                        }
                    }

                }
            } else {
                warning("Container not deleted because TRUE must be passed to `delete`.")
            }
        },
        list_files = function(full.names = FALSE) {
            return(list(
                data = list.files(paste(self$dir, ".stain", "data", sep = "/"),
                                  full.names = full.names),
                sources = list.files(paste(self$dir, ".stain", "sources", sep = "/"),
                                     full.names = full.names)
            ))
        },
        submit = function(user = private$user, host = private$host,
                          submit_dir = "~/stain", dependency_list = "") {
            private$is_submitting = TRUE

            tryCatch({
                stain_message_source_files(self$list_files(TRUE)$sources,
                                           private$is_submitting)
            }, error = function(e) {
                private$is_submitting = FALSE
                stop(e)
            })

            tryCatch({
                message("Saving globals...")
                private$save_globals()
            }, error = function(e) {
                private$is_submitting = FALSE
                stop("A global may not have an NA value. Aborting submission.", call. = FALSE)
            })

            tryCatch({
                message("Uploading components...")
                remote_host <- paste0(user, "@", host, ":", submit_dir)
                stain_scp(from = self$dir, to = remote_host)

                message("Submitting job...")
                job_dir <- paste(submit_dir, basename(self$dir), sep = "/")

                # Add any dependencies to sbatch command.
                history <- self$submission_history()$job_id
                dependencies <- sbatch_dependency_list(dependency_list, history)
                submit_cmd <- paste("sbatch submit.slurm",
                                    sbatch_opt("-d", dependencies))
                submit_cmd <- paste("cd", job_dir, "&&", submit_cmd)
                output <- stain_ssh(user, host, submit_cmd, intern = TRUE)

                # Add the job id to submission history
                output <- strsplit(output, " ")[[1]]
                job_id <- as.numeric(output[length(output)])
                stain_sub_history_append(self$dir, job_id)

                message(paste("Submitted job", job_id, "to", remote_host))
            }, error = function(e) {
                private$is_submitting = FALSE
                stop(e)
            })

            private$is_submitting = FALSE
        },
        fetch_output = function(user = private$user, host, submit_dir = "~/stain") {
            output_dir <- paste0(basename(self$dir), "/output")
            remote_output_dir <- paste0(user, "@", host, ":", submit_dir, "/", output_dir)
            stain_scp(from = remote_output_dir,  to = self$dir)
        },
        set_remote_host = function(user = private$user, host = private$host) {
            private$user <- user
            private$host <- host
        },
        submission_history = function() {
            # `stain_sub_history` will warn if submission history is empty.
            history <- stain_sub_history(self$dir)

            if (is.data.frame(history)) {
                return(history)
            }
        },
        fetch_job_states = function(user = private$user, host = private$host) {
            job_ids <- stain_sub_history(self$dir)$job_id

            verify_state_table <- function(state_table) {
                if (nrow(status_table) > 0) {
                    return(state_table)
                } else {
                    job_ids <- paste(job_ids, collapse = ", ")
                    message(paste("No statuses found for job ids:", job_ids))
                }
            }

            fetch_squeue_table <- function() {
                tryCatch({
                    squeue_table <- stain_ssh_squeue(user, host, job_ids)
                    squeue_table <- squeue_table[, c("JOBID", "STATE")]
                    colnames(squeue_table) <- c("job_id", "state")
                    # Will throw error if data frame has no rows.
                    squeue_table$exit_code <- NA
                },
                error = function(e) {
                    # An empty data frame without columns will successfully row
                    # bind with any other data frame.
                    squeue_table <- data.frame()
                }, finally = return(squeue_table))
            }

            fetch_sacct_table <- function() {
                tryCatch({
                    sacct_table <- stain_ssh_sacct(user, host, job_ids)
                    colnames(sacct_table) <- c("job_id", "state", "exit_code")
                },
                error = function(e) {
                    # An empty data frame without columns will successfully row
                    # bind with any other data frame.
                    sacct_table <- data.frame()
                }, finally = return(sacct_table))
            }

            squeue_table <- fetch_squeue_table()
            sacct_table <- fetch_sacct_table()
            states <- rbind(squeue_table, sacct_table)
            states <- aggregate(states, list(states$job_id), function(x) {
                na.omit(x)[1]
            })[,-1]

            return(states)
        }
    ),
    private = list(
        user = NULL,
        host = NULL,
        options = NULL,
        is_submitting = FALSE,
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
            if (length(globals) > 0) {
                stain_message_globals(globals, private$is_submitting)
            }

            self$globals <- globals
        },
        save_globals = function() {
            private$clean_object_files()

            for (name in names(self$globals)) {
                private$add_object(name, self$globals[[name]])
            }
        },
        rand_alphanumeric = function(len = 3) {
            population <- c(rep(0:9, each = 5), LETTERS, letters)
            samp <- sample(population, len, replace = TRUE)
            return(paste(samp, collapse = ''))
        }
    )
)
