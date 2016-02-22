#!/bin/bash 
#SBATCH --account=mpccc
#SBATCH --job-name=edison-pynamic-200-tmpfs
#SBATCH --nodes=200
#SBATCH --ntasks-per-node=24
#SBATCH --output=slurm-edison-pynamic-200-tmpfs-%j.out
#SBATCH --partition=regular
#SBATCH --qos=premium
#SBATCH --time=00:30:00

# Load modules.

module swap PrgEnv-intel PrgEnv-gnu
module load python
module list

# Verbose debugging output.

set -x

# Stage Pynamic to target filesystem.

PYNAMIC_SRC=/usr/common/usg/pynamic/pynamic-pyMPI-2.6a1
PYNAMIC_DIR=/dev/shm/pynamic/$SLURM_JOBID
umask 0000
srun -n $SLURM_JOB_NUM_NODES mkdir -p $PYNAMIC_DIR
srun -n $SLURM_JOB_NUM_NODES cp -r $PYNAMIC_SRC/* $PYNAMIC_DIR/.

# Main benchmark run.

export LD_LIBRARY_PATH="$PYNAMIC_DIR:$LD_LIBRARY_PATH"
time srun $PYNAMIC_DIR/pynamic-pyMPI $PYNAMIC_DIR/pynamic_driver.py `date +"%s"`

# Debug run.

export LD_DEBUG=libs
time srun -n 1 $PYNAMIC_DIR/pynamic-pyMPI $PYNAMIC_DIR/pynamic_driver.py `date +"%s"`

# Clean up.

srun -n $SLURM_JOB_NUM_NODES rm -rf $PYNAMIC_DIR

# For usgweb.

if [ "$USER" == "fbench" ]; then
    touch $SCRATCH/Edison_Perf/Pynamic/$SLURM_JOB_ID
fi
