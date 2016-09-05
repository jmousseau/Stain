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
        }
    ),
    private = list(
        settings = NA,
        cat_main_file_magic = function(dir, main_file) {
            main_file <- paste0(".default_stain_main.R")
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

R CMD BATCH ./.stain/sources/.default_stain_main.R

cp -r * $SLURM_SUBMIT_DIR/output"

            write(paste(private$settings$for_slurm_script(), contents, sep = "\n"),
                  file = paste(dir, "submit.slurm", sep = "/"))
        }
    )
)
