#!/bin/bash 
#SBATCH --account=mpccc
#SBATCH --job-name=edison-pynamic-200-tmpfs
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=rcthomas@lbl.gov
#SBATCH --nodes=200
#SBATCH --ntasks-per-node=24
#SBATCH --output=slurm-edison-pynamic-200-tmpfs-%j.out
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
module load python

# Optional debug output.

if [ $debug = true ]; then
    module list
    set -x
fi

# Stage Pynamic.

benchmark_src=/usr/common/usg/pynamic/pynamic-pyMPI-2.6a1
benchmark_dest=/dev/shm/pynamic/$SLURM_JOBID
benchmark_path=$benchmark_dest/pynamic-pyMPI-2.6a1

srun -n $SLURM_JOB_NUM_NODES mkdir -p $benchmark_dest
sleep 5
time srun -n $SLURM_JOB_NUM_NODES rsync -az $benchmark_src $benchmark_dest
sleep 5
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
