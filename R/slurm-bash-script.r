#' SlurmBashScript R6 object.
#'
#' Generates the necessary bash script to submit through
#' the `sbatch` command.
SlurmBashScript <- R6::R6Class("SlurmBashScript",
    public = list(
        initialize = function(container_dir, options) {
            private$options <- options

            private$cat_main_file_magic(container_dir)
            private$write_slurm_script(container_dir)
        }
    ),
    private = list(
        options = NA,
        cat_main_file_magic = function(dir) {
            main_file <- ".default_stain_main.R"
            file <- paste0(dir, "/.stain/sources/", main_file)
            sourcing <- paste("sapply(list.files('./.stain/sources', full.names = TRUE)[!(list.files('./.stain/sources')) %in%",
                              paste0("'", main_file, "'"), "], source)")
            loading <- paste("sapply(list.files('./.stain/objects', full.names = TRUE),
                             function(file) { load(file, env = .GlobalEnv) })")
            running_main <- "main()"

            cat("\n\n", sourcing, loading, running_main, file = file, append = TRUE, sep = "\n")
        },
        write_slurm_script = function(dir) {
            contents <- "#!/bin/bash

# copy necessary files over
cp -r ./.stain $PFSDIR
mkdir ./output
cd $PFSDIR

mkdir ./data
mv ./.stain/data/* ./data

module load hpc-ods
module load pandoc

R CMD BATCH ./.stain/sources/.default_stain_main.R

rm -rf ./data ./.stain

cp -r * $SLURM_SUBMIT_DIR/output

rm -rf *"

            write(contents, file = paste(dir, "submit.slurm", sep = "/"))
        }
    )
)
