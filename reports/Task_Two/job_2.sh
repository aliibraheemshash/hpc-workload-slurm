#!/bin/bash
#SBATCH --job-name=second_job
#SBATCH --time=00:01:20




sbatch --cluster=ali --dependency=afterok:$SLURM_JOB_ID job_3.sh
sbatch --cluster=shash --dependency=afterok:$SLURM_JOB_ID job_4.sh

sleep 10

