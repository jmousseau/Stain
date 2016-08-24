
#!/bin/bash
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

R CMD BATCH ./source/$1

for i in ${@:2}
do
cp -r $i $SLURM_SUBMIT_DIR/output
done

cp -r './$1out' $SLURM_SUBMIT_DIR/output
