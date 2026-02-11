# SLURM_DAGMan Code Documentation

This document describes the internal structure, logic, and behavior of the `SLURM_DAGMan` Python implementation.  
The code provides a lightweight workflow manager that parses a DAG description file and submits dependent jobs to SLURM using `sbatch`.

---

## Class: SLURM_DAGMan
The `SLURM_DAGMan` class encapsulates all logic related to parsing, validating, and executing DAG-based SLURM workflows.
#### Constructor
Initializes the DAG manager with a workflow description file.
**-** `dagFile`: Path to the DAG description file
**-** `jobs`:	List of job dictionaries
**-** `submit_descriptions`:	Mapping of template names to SLURM script content

```python
def __init__(self, dagFile)
```
### Method: `parse()`

#### Purpose

Parses the DAG description file and builds the internal job and dependency structures.

#### Responsibilities

* Reads the DAG file line by line
* Extracts `SUBMIT-DESCRIPTION` blocks
* Parses job definitions (`JOB`)
* Parses dependency definitions (`PARENT … CHILD …`)
* Detects syntax errors and cyclic dependencies

#### Key Behaviors

* Inline SLURM templates are automatically prepended with `#!/bin/bash`
* Indentation is removed using `textwrap.dedent` to ensure `#SBATCH` directives are recognized by `sbatch`
* Comments and empty lines are ignored

---
#### 1. SUBMIT-DESCRIPTION Handling

While parsing, the following state variables are used:

| Variable             | Role                                                    |
| -------------------- | ------------------------------------------------------- |
| `recording_desc`     | Indicates whether the parser is inside a template block |
| `current_desc_name`  | Name of the active submit description                   |
| `current_desc_lines` | Buffer storing script lines                             |

When a closing `}` is encountered:

* The collected lines are dedented
* The template is stored in `submit_descriptions`

---
#### 2. JOB Parsing

##### Syntax Handled

```text
JOB &lt;JobName&gt; &lt;DescriptionName | script_file&gt; [cluster_name]
```

##### Parsed Job Fields

Each job is stored as a dictionary with the following keys:

| Key              | Description                           |
| ---------------- | ------------------------------------- |
| `name`           | Job identifier                        |
| `script`         | SLURM script file to submit           |
| `script_content` | Inline script content (if applicable) |
| `is_inline`      | Indicates inline or file-based script |
| `cluster`        | Optional cluster name                 |
| `parents`        | Set of parent job names               |
| `children`       | Set of child job names                |
| `ID`             | SLURM job ID after submission         |

---

#### 3. Dependency Parsing (`PARENT / CHILD`)

##### Syntax Handled

```text
PARENT &lt;parents&gt; CHILD &lt;children&gt;
```

#### Behavior

* Parent and child job names are resolved to job objects
* Parent jobs are linked to children and vice versa
* Cyclic dependencies are detected using ancestor traversal

---

### Method: `_getJobAncestors(jobName)`

#### Purpose

Recursively determines all ancestor jobs of a given job.

#### Use Case

* Detects cycles in the dependency graph
* Prevents invalid DAG definitions

---
### Method: `run()`

#### Purpose

Starts workflow execution.

#### Behavior

* Identifies leaf jobs (jobs with no children)
* Submits leaf jobs, triggering recursive dependency submission

---
### Method: `_submit(jobName)`

#### Purpose

Submits a job to SLURM with correct dependency handling.

#### Execution Steps

1. Writes inline SLURM scripts to disk if needed
2. Builds the `sbatch` command
3. Appends `--cluster` option if specified
4. Resolves parent jobs recursively
5. Adds `--dependency=afterok`
6. Executes `sbatch`
7. Extracts and stores the SLURM job ID

---

### Method: `_getJob(lineNo, jobName)`

#### Purpose

Retrieves a job dictionary by name.

#### Behavior

* Returns the job if found
* Terminates execution if the job is undefined

---
### Method: `_Error(lineNo, errorNo, message)`

#### Purpose

Centralized error reporting and termination.

#### Supported Error Types

| Code | Meaning                        |
| ---- | ------------------------------ |
| `0`  | Invalid syntax                 |
| `1`  | Invalid PARENT/CHILD statement |
| `2`  | Invalid JOB statement          |
| `10` | Custom error message           |

All errors terminate execution immediately using `os._exit()`.

---
### Method: `_getJobString(job)`

#### Purpose

Formats a single job’s information for display.

#### Output Includes

* Job name
* Cluster (if any)
* SLURM job ID
* Parent jobs
* Child jobs

---
### Method: `__str__()`

#### Purpose

Returns a human-readable summary of all jobs in the workflow.

---
### Function: `main(argv)`

#### Purpose

Command-line entry point.

#### Behavior

* Validates arguments
* Loads the DAG file
* Creates a `SLURM_DAGMan` instance
* Parses and runs the workflow
* Prints execution summary

---

### Program Entry Point

```python
if __name__ == "__main__":
    main(sys.argv[1:])
```

Ensures the script executes only when run directly.

---
## Summary

This code implements a minimal DAG-based SLURM workflow engine that:

* Parses a custom DAG syntax
* Validates dependencies
* Prevents cyclic execution
* Submits jobs using native SLURM mechanisms

The design prioritizes correctness, simplicity, and direct interaction with `sbatch`.
