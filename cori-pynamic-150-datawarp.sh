#!/bin/bash 
#SBATCH --account=mpccc
#SBATCH --job-name=cori-pynamic-150-datawarp
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=rcthomas@lbl.gov
#SBATCH --nodes=150
#SBATCH --ntasks-per-node=32
#SBATCH --output=slurm-cori-pynamic-150-datawarp-%j.out
#SBATCH --partition=regular
#SBATCH --qos=normal
#SBATCH --time=25
#DW jobdw capacity=2TB access_mode=striped type=scratch

# Load modules.

module unload python
module unload altd
module swap PrgEnv-intel PrgEnv-gnu
module load python
module list

# Verbose debugging output.

set -x

# Stage Pynamic.

benchmark_src=/usr/common/software/pynamic/pynamic/pynamic-pyMPI-2.6a1
benchmark_dest=$DW_JOB_STRIPED
benchmark_path=$benchmark_dest/pynamic-pyMPI-2.6a1

time rsync -az $benchmark_src $benchmark_dest
export LD_LIBRARY_PATH=$benchmark_path:$LD_LIBRARY_PATH

# Allows up to 5 minutes for pynamic-pyMPI to MPI_Init().

export PMI_MMAP_SYNC_WAIT_TIME=300

# Run benchmark.

time srun $benchmark_path/pynamic-pyMPI $benchmark_path/pynamic_driver.py $(date +%s)

# Debug run.

export LD_DEBUG=libs
time srun -n 1 $benchmark_path/pynamic-pyMPI $benchmark_path/pynamic_driver.py $(date +%s)

# For usgweb.

if [ "$USER" == "fbench" ]; then
    touch $SCRATCH/Cori_Perf/Pynamic/$SLURM_JOB_ID
fi
