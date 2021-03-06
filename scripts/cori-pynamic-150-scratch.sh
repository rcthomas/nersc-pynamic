#!/bin/bash 
#SBATCH --account=mpccc
#SBATCH --job-name=cori-pynamic-150-scratch
#SBATCH --license=SCRATCH
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=rcthomas@lbl.gov
#SBATCH --nodes=150
#SBATCH --ntasks-per-node=32
#SBATCH --output=logs/slurm-cori-pynamic-150-scratch-%j.out
#SBATCH --partition=regular
#SBATCH --qos=normal
#SBATCH --time=45

# Configuration.

commit=true
debug=false

# Load modules.

module unload python
module unload altd
module swap PrgEnv-intel PrgEnv-gnu
module load python_base

# Optional debug output.

if [ $debug = true ]; then
    module list
    set -x
fi

# Stage Pynamic.

benchmark_src=/usr/common/software/pynamic/pynamic/pynamic-pyMPI-2.6a1
benchmark_dest=$SCRATCH/staged-pynamic
benchmark_path=$benchmark_dest/pynamic-pyMPI-2.6a1

mkdir -p $benchmark_dest
time rsync -az $benchmark_src $benchmark_dest
export LD_LIBRARY_PATH=$benchmark_path:$LD_LIBRARY_PATH

# Initialize benchmark result.

if [ $commit = true ]; then
    module load mysql
    module load mysqlpython
    python report-benchmark.py initialize
    module unload mysqlpython
fi

# Sanity checks.

echo PYTHONPATH: $PYTHONPATH

# Run benchmark.

output=latest-$SLURM_JOB_NAME.txt
time srun $benchmark_path/pynamic-pyMPI $benchmark_path/pynamic_driver.py $(date +%s) | tee $output

# Extract result.

startup_time=$( grep '^Pynamic: startup time' $output | awk '{ print $(NF-1) }' )
import_time=$( grep '^Pynamic: module import time' $output | awk '{ print $(NF-1) }' )
visit_time=$( grep '^Pynamic: module visit time' $output | awk '{ print $(NF-1) }' )
total_time=$( echo $startup_time + $import_time + $visit_time | bc )

# Finalize benchmark result.

if [ $commit = true ]; then
    module load mysqlpython
    python report-benchmark.py finalize $total_time
fi

# Debug run.

export LD_DEBUG=libs
time srun -n 1 $benchmark_path/pynamic-pyMPI $benchmark_path/pynamic_driver.py $(date +%s)
