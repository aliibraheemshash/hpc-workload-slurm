## SLURM Dependency Mechanisms and Workflow Overview
### 1. Overview
Before diving into the workflow implementation, it is essential to explain how SLURM handles job dependencies, that is, how one job can wait for another job to start, finish, fail, or succeed before it begins execution.
SLURM provides this functionality through the `--dependency` flag in the `sbatch` command.
This flag accepts dependency keys followed by one or more job IDs, separated by colons.
The general pattern is:
```batch
--dependency=key:<jobID_1>:<jobID_2>:... , key:<jobID_1>:<jobID_2>:...
```
The most relevant dependency keys, summarized from the official SLURM documentation:
- `after:jobid[+time]`
  Job B starts after Job A starts or is cancelled, optionally after a delay of `<time>` minutes.
- `afterany:jobid`
  Job B starts after Job A has terminated, regardless of success or failure.
- `afternotok:jobid`
  Job B starts only if job A fails.
For full reference, see the official SLURM manual:
🔗 https://slurm.schedmd.com/sbatch.html#OPT_dependency
### 2. Workflow Context
This document describes the workflow implemented to coordinate a sequence of dependent SLURM jobs across two clusters (Cluster A → Cluster B).
The execution sequence is:
`job1  →  job2  →  job3  →  job4`
Each job is automatically submitted only after the previous job successfully begins, but the dependency ensures that it does not actually execute until the prior job has fully completed with exit code 0 (using `afterok`).
### 3. Justification for Using $SLURM_JOB_ID
To correctly chain dependent jobs, we need the job ID of the currently running job.
SLURM provides this value through the environment variable: `$SLURM_JOB_ID`
Why this is required
- We cannot know a job ID before submitting the job, since SLURM assigns IDs dynamically at submission time.
- SLURM_JOB_ID is guaranteed to represent the parent running job, so the dependency is always attached to the correct batch script.
### 4. Implementation Command
To execute the workflow, we begin by submitting the first job on Cluster A:
`sbatch --cluster=ali job_1.sh`
Subsequent scripts repeat the same mechanism, forming a deterministic execution chain:
`job_1.sh → job_2.sh → job_3.sh → job_4.sh`
The following figures show the observed execution behavior of the workflow.
At any moment, one job is running while the next job is queued with an unsatisfied dependency.
hpc-workload-slurm/reports/Task_Two/Images/First.png
hpc-workload-slurm/reports/Task_Two/Images/Second.png
hpc-workload-slurm/reports/Task_Two/Images/Third.png
hpc-workload-slurm/reports/Task_Two/Images/Fourth.png
