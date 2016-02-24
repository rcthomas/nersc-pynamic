#!/bin/bash

job_id=`sbatch                               cori-pynamic-150-common.sh   | awk '{ print $NF }'`
echo $job_id

job_id=`sbatch --dependency=afterany:$job_id cori-pynamic-150-datawarp.sh | awk '{ print $NF }'`
echo $job_id

job_id=`sbatch --dependency=afterany:$job_id cori-pynamic-150-project.sh  | awk '{ print $NF }'`
echo $job_id

job_id=`sbatch --dependency=afterany:$job_id cori-pynamic-150-scratch.sh  | awk '{ print $NF }'`
echo $job_id

job_id=`sbatch --dependency=afterany:$job_id cori-pynamic-150-tmpfs.sh    | awk '{ print $NF }'`
echo $job_id

squeue -o "%10i %10u %10a %30j %10P %10q %5D %10l %10M %2t %S" -u $USER
