#!/bin/bash
#SBATCH --account=mpccc
#SBATCH --image=docker:registry.services.nersc.gov/pynamic:2.6a1
#SBATCH --job-name=cori-pynamic-150-shifter
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=rcthomas@lbl.gov
#SBATCH --nodes=150
#SBATCH --ntasks-per-node=32
#SBATCH --output=slurm-cori-pynamic-150-shifter-%j.out
#SBATCH --partition=regular
#SBATCH --qos=normal
#SBATCH --time=25

# Verbose debugging output.

set -x

# Unset variables.

unset PYTHONSTARTUP
unset PYTHONPATH
unset LD_LIBRARY_PATH
unset CRAY_LD_LIBRARY_PATH
unset LIBRARY_PATH

# Allows up to 5 minutes for pynamic-pyMPI to MPI_Init().

export PMI_MMAP_SYNC_WAIT_TIME=300

# Run benchmark.

module load shifter
srun shifter /bench/pynamic-pyMPI /bench/pynamic_driver.py $(date +%s)

# For usgweb.

if [ "$USER" == "fbench" ]; then
    touch $SCRATCH/Cori_Perf/Pynamic/$SLURM_JOB_ID
fi
