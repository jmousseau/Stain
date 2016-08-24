#' SlurmBashScript R6 object.
#'
#' Generates the necessary bash script to submit through
#' the `sbatch` command.
SlurmBashScript <- R6::R6Class("SlurmBashScript",
    public = list(
        initialize = function(container, main_file, copy_back = c("*")) {
            private$cat_main_file_magic(container$dir, main_file)
            private$write_slurm_script(container$dir)
            private$write_submit_script(container$dir, main_file, copy_back)
        }
    ),
    private = list(
        cat_main_file_magic = function(dir, main_file) {
            file <- paste(dir, "sources", basename(main_file), sep = "/")
            sourcing <- paste("sapply(list.files('./sources')[!(",
                              paste0("'", main_file, "'"),
                              "%in% list.files('./sources'))], source)")
            loading <- paste("sapply(list.files('./.objects'), load)")
            running_main <- "main()"

            cat(sourcing, loading, running_main, file = file, append = TRUE, sep = "\n")
        },
        write_slurm_script = function(dir) {
            contents <- "#!/bin/bash
#SBATCH --nodes=1
#SBATCH --cpus-per-task=12
#SBATCH --time=0:10:00
#SBATCH --mem=16g
#SBATCH -o R_job.o%j


# copy necessary files over
cp -r ./sources ./input ./.objects $PFSDIR
cd $PFSDIR

module load hpc-ods
module load pandoc

# Flatten input directory
mv -r ./input .

main_file=$(basename $1)

R CMD BATCH ./sources/$main_file

for i in ${@:2}
do
cp -r $i $SLURM_SUBMIT_DIR/output
done

cp -r './$1out' $SLURM_SUBMIT_DIR/output"

            write(contents, file = paste(dir, ".static.slurm", sep = "/"))
        },
        write_submit_script = function(dir, main_file, copy_back) {
            contents <- paste("#!/bin/bash\nsbatch ./.static.slurm", main_file, copy_back)
            write(contents, file = paste(dir, "submit.sh", sep = "/"))
        }
    )
)
