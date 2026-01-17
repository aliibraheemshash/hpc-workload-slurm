# SLURM Installation Guide (with MUNGE and MariaDB)

This document provides a step-by-step installation and configuration guide for **MUNGE**, **MariaDB**, and **SLURM Workload Manager** on a Linux system.  
The guide follows security best practices and explains *why* each component is required.

---

## Table of Contents

1. Overview  
2. Installing and Configuring MUNGE  
3. Verifying MUNGE Installation  
4. Why MUNGE Must Start Before SLURM  
5. Installing and Configuring MariaDB for SLURM  
6. Installing SLURM from Source  
7. SLURM Configuration Files  
8. Starting SLURM Daemons  
9. Final Verification  

---

## 1. Overview

SLURM relies on **MUNGE** for authentication and **MariaDB** for accounting and job history.  
For security and correctness:

- MUNGE must run under its own system user  
- SLURM must run under a dedicated `slurm` user  
- Services must be started in the correct order  

> ⚠️ Running everything under a normal user (e.g., `ali`) breaks security guarantees and can lead to cluster failures.

---

## 2. Installing and Configuring MUNGE

### 2.1 Create the MUNGE System User

MUNGE manages authentication credentials and should **never** run as a normal user.

```bash
export MUNGEUSER=3443

sudo groupadd -g $MUNGEUSER munge
sudo useradd -m \
  -c "MUNGE Uid 'N' Gid Emporium" \
  -d /var/lib/munge \
  -u $MUNGEUSER \
  -g munge \
  -s /sbin/nologin munge
```
### 2.2 Install MUNGE Packages
```bash
sudo apt install -y libmunge-dev libmunge2 munge
```
### 2.3 Set Ownership and Permissions
```bash
sudo chown -R munge: /etc/munge/ /var/log/munge/ /var/lib/munge/ /run/munge/
sudo chmod 400 /etc/munge/ /var/log/munge/ /var/lib/munge/ /run/munge/
```
### 2.4 Create the MUNGE Key (If Missing)
Check whether the key exists:
```bash
cd /etc/munge/
ls
```
If the directory is empty, generate the key:
```bash
sudo -u munge /usr/sbin/mungekey --verbose
chmod 400 munge.key
```
### 2.5 Enable and Start MUNGE
```bash
sudo systemctl enable munge
sudo systemctl start munge
```
## 3. Verifying MUNGE Installation

Run the following test:
```bash
munge -n | unmunge
```
Expected output includes:
```
STATUS:     Success (0)
```
## 4. Why MUNGE Must Start Before SLURM

If SLURM starts before MUNGE, the following errors may occur:
- Authentication error
- Munge decode failed
- Security violation
- Invalid credential
### Job Submission Workflow
When submitting a job:
```bash
sbatch myjob.sh
```
Internally, SLURM performs:
1. `sbatch` requests a credential from MUNGE
2. The credential is sent to `slurmctld`
3. `slurmctld` verifies it using MUNGE
4. The job is accepted
5. The credential is sent to `slurmd`
6. `slurmd` verifies it again
7. The job runs as the correct user

## 5. Installing and Configuring MariaDB for SLURM

SLURM uses a database for accounting, job history, and resource usage tracking.
### 5.1 Create the SLURM System User
```bash
export SLURMUSER=3444

sudo groupadd -g $SLURMUSER slurm
sudo useradd -m \
  -c "SLURM Workload Manager" \
  -d /var/lib/slurm \
  -u $SLURMUSER \
  -g slurm \
  -s /bin/bash slurm
```
### 5.2 Create the SLURM Database
Login as root:
```bash
sudo mysql -u root
```
Inside MariaDB:
```bash
CREATE DATABASE slurm_acct_db;

GRANT ALL ON slurm_acct_db.*
TO 'slurm'@'localhost'
IDENTIFIED BY 'slurm@1234'
WITH GRANT OPTION;

FLUSH PRIVILEGES;
```
Verify:
```bash
SELECT user FROM mysql.user;
```
Exit
```bash
EXIT;
```
## 6. Installing SLURM from Source

### 6.1 Download SLURM
Clone or download the desired SLURM version and extract it.

### 6.2 Configure SLURM
```bash
./configure \
  --prefix=/usr/local \
  --with-mysql_config=/usr/bin/mariadb_config
```
Explanation:
- `--prefix=/usr/local`
SLURM files are installed under `/usr/local`

- `--with-mysql_config`
Enables MariaDB accounting support
If errors appear due to missing libraries, install them and re-run `configure`.

### 6.3 Build and Install
```bash
make
make check    # optional
sudo make install
```
## 7. Post-Installation Directory Setup

```bash
sudo mkdir -p /var/spool/slurmctld /var/spool/slurmd /var/log/slurm
sudo chown slurm: /var/spool/slurmctld /var/spool/slurmd /var/log/slurm
```
## 8. SLURM Configuration Files

Main Files
- `slurm.conf` — cluster configuration
- `slurmdbd.conf` — database connection
- `topology.conf` — cluster topology

Service Files
- `slurmctld.service`
- `slurmd.service`
- `slurmdbd.service`
  
>⚠️ Modify all configuration files according to your system before use.

File Placement
```bash
sudo cp slurm.conf topology.conf slurmdbd.conf /usr/local/etc/
sudo cp slurmctld.service slurmdbd.service slurmd.service /etc/systemd/system/
```
## 9. Starting SLURM Daemons

Enable services:
```bash
sudo systemctl enable slurmdbd
sudo systemctl enable slurmctld
sudo systemctl enable slurmd
```
Start and verify:
```bash
sudo systemctl start slurmdbd
sudo systemctl status slurmdbd

sudo systemctl start slurmctld
sudo systemctl status slurmctld

sudo systemctl start slurmd
sudo systemctl status slurmd
```
## 🎉 Final Notes
If all services start without errors, SLURM is successfully installed and operational.

Congratulations—you now have a secure and correctly configured SLURM environment.
