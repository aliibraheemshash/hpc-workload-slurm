#!/bin/bash
#SBATCH --job-name=firt_job
#SBATCH --time=00:01:20


sbatch --cluster=shash --dependency=afterok:$SLURM_JOB_ID job_2.sh
sleep 10




