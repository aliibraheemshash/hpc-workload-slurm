# Job Workflow Configuration Guide

This document describes the syntax and structure for defining job dependencies and Slurm execution templates in a single `.sdag` configuration file. 
---

## 1. Structure Overview

The configuration file is divided into three main sections:

1. **Job Template (`SUBMIT-DESCRIPTION`)**  
   Defines the Slurm script blueprint.

2. **Job Definitions**  
   Maps specific tasks to the template and target clusters.

3. **Dependency Architecture**  
   Defines the execution order using a Directed Acyclic Graph (DAG).

---

## 2. The Job Template (`SUBMIT-DESCRIPTION`)

The first part of the file defines the Slurm parameters and the commands to be executed on each node.

### Example

```bash
SUBMIT-DESCRIPTION DiamondDesc {
#SBATCH --job-name=Job
#SBATCH --time=00:02:00
#SBATCH --mem=200M
#SBATCH --nodes=128
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

sleep 30
}
```
### ⚠️ Critical Syntax Rules
To ensure the job submission engine processes the file correctly, you must follow these rules:

1. **Shebang**  
Do not add `#!/bin/bash`.
The system automatically injects this at the top of the generated file.

2. **Leading Spaces**  
Do not add any spaces or tabs before `#SBATCH` directives or commands.  
When the job is submitted using `sbatch`, any leading whitespace will prevent `#SBATCH` directives from being recognized by the Slurm parser, causing them to be ignored.

3. **Naming**
The name following SUBMIT-DESCRIPTION (e.g., DiamondDesc) is used to link jobs to this specific template.

## 3. Job Definitions
Once the template is defined, individual job instances must be declared.
#### Syntax
```batch
JOB [JobName] [DescriptionName] [ClusterName]
```
### Parameters
1. **JobName**
A unique identifier for the specific task.

2. **DescriptionName**
Must exactly match the name used in the SUBMIT-DESCRIPTION header.

3. **ClusterName (Optional)**
Used for cross-cluster job execution and dependencies.
#### Example
```batch
JOB A DiamondDesc cluster_A
JOB B DiamondDesc cluster_B
```
## 4. Workflow Architecture
The final section defines the relationship and execution order between the defined jobs using a parent–child dependency model.
#### Syntax
```batch
PARENT [Job] CHILD [Job]
```
**-** The child job will begin execution only after the parent job has successfully completed.

**-** Multiple parents or children may be listed in a single line to construct complex workflows.
#### Example
```batch

PARENT A CHILD B C     # B and C start after A finishes
PARENT B C CHILD D     # D starts only after both B and C finish
```
