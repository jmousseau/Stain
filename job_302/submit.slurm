#!/bin/bash
#SBATCH --nodes=1
#SBATCH --mem=8g
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:00
#SBATCH --mail-user=mousseau@case.edu
#SBATCH --mail-type=BEGIN,END,FAIL

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
