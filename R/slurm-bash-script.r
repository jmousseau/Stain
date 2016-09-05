#' SlurmBashScript R6 object.
#'
#' Generates the necessary bash script to submit through
#' the `sbatch` command.
SlurmBashScript <- R6::R6Class("SlurmBashScript",
    public = list(
        initialize = function(container, main_file, settings) {
            private$settings <- settings

            main_file <- paste0("cp_of_", main_file)

            private$cat_main_file_magic(container$dir, main_file)
            private$write_slurm_script(container$dir)
            private$write_submit_script(container$dir, main_file)
        }
    ),
    private = list(
        settings = NA,
        cat_main_file_magic = function(dir, main_file) {
            main_file <- paste0("cp_of_", basename(main_file))
            file <- paste(dir, ".stain/sources", main_file, sep = "/")
            sourcing <- paste("sapply(list.files('./.stain/sources', full.names = TRUE)[!(list.files('./sources')) %in%",
                              paste0("'", main_file, "'"), "], source)")
            loading <- paste("sapply(list.files('./.stain/objects', full.names = TRUE),
                             function(file) { load(file, env = .GlobalEnv) })")
            running_main <- "main()"

            cat("\n\n", sourcing, loading, running_main, file = file, append = TRUE, sep = "\n")
        },
        write_slurm_script = function(dir) {
            contents <- "
# copy necessary files over
cp -r ./.stain $PFSDIR
cd $PFSDIR

module load hpc-ods
module load pandoc

main_file=$(basename $1)

R CMD BATCH ./.stain/sources/$main_file

cp -r * $SLURM_SUBMIT_DIR/output"

            write(paste(private$settings$for_slurm_script(), contents, sep = "\n"),
                  file = paste(dir, ".static.slurm", sep = "/"))
        },
        write_submit_script = function(dir, main_file) {
            contents <- paste("#!/bin/bash\nsbatch ./.static.slurm", main_file)
            write(contents, file = paste(dir, "submit.sh", sep = "/"))
        }
    )
)
