#' Write the stain slurm submission script
#'
#' @param dir The location of the \code{.stain/} directory.
stain_bash_slurm_write <- function(dir) {
    # Use to conditionally write a line of file.
    wl_if <- function(line, should_write = TRUE) {
        if (should_write) {
            cat(line, file = paste0(dir, "/submit.slurm"),
                append = TRUE, sep = "\n")
        }
    }

    wl_if("#!/bin/bash")

    # Copy necessary files to submission directory.
    wl_if("cp -r ./.stain $PFSDIR")
    wl_if("mkdir ./output")

    wl_if("cd $PFSDIR")

    wl_if("mkdir ./data")
    wl_if("mv ./.stain/data/* ./data")

    # Load the necessary modules.
    wl_if("module load hpc-ods")
    wl_if("module load pandoc")

    # Run the default main script.
    wl_if("R CMD BATCH ./.stain/sources/.default_stain_main.R $1")

    # Copy back the log files.
    wl_if("cp -r ./.stain/logs $SLURM_SUBMIT_DIR/.stain/")

    # Remove the unimportant folders.
    wl_if("rm -rf ./data ./.stain")

    # Now copy back the output.
    wl_if("cp -r * $SLURM_SUBMIT_DIR/output")

    # Clean up.
    wl_if("rm -rf *")
}


#' Write the default main R file.
#'
#' @param dir The location of the \code{.stain/} directory.
stain_default_main_write <- function(dir) {
    wl <- function(line) {
        main_file <- paste0(dir, "/.stain/sources/.default_stain_main.R")
        cat(line, file = main_file, append = TRUE, sep = "\n")
    }

    wl("all_sources <- list.files('./.stain/sources', full.names = TRUE)")

    # Source all the sources.
    wl("sources <- list.files('./.stain/sources')")
    wl("sources <- all_sources[!(sources %in% '.default_stain_main.R')]")
    wl("sapply(sources, source)")

    # Load all the objects into the global environment.
    wl("all_objects <- list.files('./.stain/objects', full.names = TRUE)")
    wl("load_object <- function(file) { load(file, env = .GlobalEnv) }")
    wl("sapply(all_objects, load_object)")

    # Run main function.
    wl("main()")
}
