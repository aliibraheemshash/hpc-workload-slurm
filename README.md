# hpc-workload-slurm
Scaling and replay tool for HPC traces on SLURM. Developed at the Dept. of CSE, IIT Kanpur (Advisor: Prof. Preeti).
## 🖥️ System Prerequisites & Environment

Before diving into the implementation, I want to clarify the system properties and features used in this setup. This ensures compatibility for anyone following this repository to reproduce the work.

| Component | Specification |
| :--- | :--- |
| **OS** | Ubuntu Desktop 25.01 |
| **Processor** | Intel Core i7 (8th Gen) |
| **RAM** | 16 GB |
| **Storage** | 1 TB HDD |

---

## 🚀 Why SLURM?

If you are working in the HPC (High-Performance Computing) domain, you might need to test a scheduling algorithm but lack a high-volume infrastructure. This repository provides the solution.

This environment allows you to simulate a cluster without the need for multiple Virtual Machines (though VMs are a valid choice in some scenarios). It is particularly useful if you are developing algorithms for:
* **Job Scheduling simulations**
* **Log Management Systems** (integrating with tools like Prometheus or Fluentd)

---

## 📥 Getting Started: Versioning & Downloads

SLURM is currently owned and maintained by SchedMD (acquired by NVIDIA). You can download the source code from their official website.

* **Latest Version:** 25.11 (Released 2025)
* **My Choice:** Version **24.7.11** (Released 2025)

> **⚠️ Important Documentation Note:**
> When reading the official documentation, ensure you are reading the docs for the **exact version** you are installing. Do not read the documentation for v25.x if you are installing v24.x. While often similar, small changes in parameters can break your configuration.

### ⛔ A Critical Warning on Installation
**Do not use `apt install slurm-client` or similar package managers blindly.**

If you try to execute a command like `sinfo` and the terminal suggests downloading the `slurm-client` package—**STOP.**
This usually means the tool was not installed correctly from the source. If you see this message, you likely need to re-install.

---

## 🏗️ SLURM Architecture Explained

To understand how this repository works, we must look at the architecture. A standard monitoring or management system requires a monitor (node), a controller, and a database to prevent data loss.

In SLURM, these components are:

1.  **`slurmctld` (The Controller):** The management daemon that monitors resources and schedules work.
2.  **`slurmd` (The Worker):** The daemon running on compute nodes to execute the work.
3.  **`slurmdbd` (The Database):** The database daemon used to store accounting data and history.



### 🔐 The Security Layer: MUNGE

Before installing the SLURM orchestration, we must install **MUNGE**. This serves as the authentication service.

**Why do we need a security layer?**
Imagine you want to send an official document to a coworker asking them to perform a task.
* In your office, there is a **Security Officer**.
* This officer verifies that the document is actually from you and related to company business.
* If verified, the coworker accepts the task. If not, the coworker ignores it.

In this system, **MUNGE is the Security Officer.**
Every job submission or order from a user is authorized by MUNGE before it is sent to the cluster. The cluster then verifies the credential again before submitting it to the node for execution.
