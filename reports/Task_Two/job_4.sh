#!/bin/bash
#SBATCH --job-name=forth_job
#SBATCH --time=00:01:20


sbatch --cluster=shash --dependency=afterok:$SLURM_JOB_ID job_3.sh

sleep 15

