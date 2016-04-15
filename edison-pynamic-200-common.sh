#!/bin/bash 
#SBATCH --account=mpccc
#SBATCH --job-name=edison-pynamic-200-common
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=rcthomas@lbl.gov
#SBATCH --nodes=200
#SBATCH --ntasks-per-node=24
#SBATCH --output=slurm-edison-pynamic-200-common-%j.out
#SBATCH --partition=regular
#SBATCH --qos=normal
#SBATCH --time=25

# Configuration.

commit=true
debug=false

# Load modules.

module unload python
module unload altd
module swap PrgEnv-intel PrgEnv-gnu
module load python_base
module load numpy

# Optional debug output.

if [ $debug = true ]; then
    module list
    set -x
fi

# Stage Pynamic

benchmark_path=/usr/common/usg/pynamic/pynamic-pyMPI-2.6a1
export LD_LIBRARY_PATH=$benchmark_path:$LD_LIBRARY_PATH

# Initialize benchmark result.

if [ $commit = true ]; then
    module load mysql
    module load mysqlpython
    python report-benchmark.py initialize
    module unload mysqlpython
fi

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
