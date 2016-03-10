
Pynamic Benchmark on Edison and Cori
====================================

This document describes the deployment and operation of the Pynamic benchmark on the Edison and Cori systems at NERSC.

Version, Installation, Configuration, and Customization
-------------------------------------------------------

Pynamic Version 1.3 has been installed on both systems using the /global/common file system.
The installation path for each machine is listed below.

    edison: /usr/common/usg/pynamic
    cori:   /usr/common/software/pynamic

Pynamic 1.3 has also been installed into a Shifter image.
In all cases the `config_pynamic.py` script supplied with Pynamic was used to perform an in-source build.
This script takes a number of arguments to shape the installation.
The Pynamic-specific arguments used on either machine were identical to the example values provided in the package documentation:

* 495 shared object files
* 1850 average functions per shared object file
* cross-module calls enabled
* 215 math library-like utility files
* 1850 average math library-like utility functions
* 100 additional characters on function names

Pynamic was linked against the Cray MPICH2 libraries provided on either machine under the GNU programming environment.
The Shifter image includes the same libraries for the Pynamic build.

Execution
---------

Batch job scripts have been configured for either machine to run Pynamic within the following test matrix.

|        | common | datawarp | project | scratch | shifter | tmpfs |
| ------ |:------:|:--------:|:-------:|:-------:|:-------:|:-----:|
| Edison | yes    | N/A      | yes     | yes     | no      | yes   |
| Cori   | yes    | yes      | yes     | yes     | yes     | yes   |

In each job (excluding the Shifter jobs), the Pynamic benchmark is first run using 4800 MPI ranks then re-run using just one MPI rank with LD_DEBUG=libs
set to capture information about what libraries Pynamic touched.
Benchmark jobs are submitted by cron only if no other job has been submitted with the same name.
A job is potentially submitted every two hours on either machine.

The Shifter script just runs the Pynamic benchmark but does not run the LD_DEBUG step.
The time-zone in the current Shifter image appears to be offset from local time resulting in a skew in the time executed.
This could be fixed a number of ways but is a minor issue.

Pynamic reports four timing numbers of interest.
These are start-up time, import time, visit time, and sample compute time.
The general Pynamic result is the sum of the first three or all four numbers.
We ignore the fourth number (sample compute) and just *sum the first three values* as our metric.
A Python script included in the benchmark directory parses the job output to extract the measurements reported by Pynamic.

*It is important to note* that these timing results are captured after all MPI ranks have completed a phase of the benchmark.
That is, the times reported are the worst-case completion time across all ranks, not an average.
This is a key difference from previous versions of Pynamic where the average time was used.
It is very important to understand this detail when discussing Pynamic results at NERSC, with vendors, or with users.

Time spent in a benchmark job staging files before the main Pynamic run is not measured as part of the benchmark.
The time spent to run with LD_DEBUG=libs set is likewise not included as part of the benchmark measurement.

### Common

In the *common* configuration Pynamic is run by launching the Pynamic driver code out of /usr/common on either machine.
The Pynamic build directory is prepended to LD_LIBRARY_PATH before the benchmark is launched.

On the three shared file system configurations Pynamic routinely performs best in the *common* configuration,
and at times it is competitive with *tmpfs* even ignoring the additional copy overhead *tmpfs* requires.

### Datawarp

The *datawarp* configuration tests Pynamic on the burst buffer.
To do this, the contents of the Pynamic build directory on /usr/common are copied to the burst buffer and the target directory is prepended to LD_LIBRARY_PATH.

Comments on performance cannot be made public at this time.

### Project and Scratch

In the *project* and *scratch* configurations, the contents of the Pynamic build directory are optionally copied to the /project
or $SCRATCH filesystems from /usr/common.
This ensures that the same configuration is being tested and keeps us from having to maintain separate builds on /project and $SCRATCH for either machine.
The copy step in the /project jobs is commented out, but remains uncommented in the $SCRATCH jobs.
Again the copied Pynamic build directory is prepended to LD_LIBRARY_PATH.

The *project* and *scratch* results generally lag behind the *common* results by a wide margin.
They are generally a factor of two or even more slower than *common*.
Interestingly, the *project* configuration seems to perform better than the *scratch* configuration on Cori,
though users seem very happy with Cori $SCRATCH performance.

### Shifter

Currently we are using the following image:

    docker:registry.services.nersc.gov/pynamic:2.6a1

The Pynamic libraries have been cached in this image by adding them to `ld.so.conf` and running `ldconfig.`
Users would not be able to do this in a regular NERSC environment but they can do it in Shifter images since they are running as root.

The *shifter* results for Pynamic generally currently tie with the baseline measurement provided by *tmpfs*.

### Baseline tmpfs

This configuration tests Pynamic on /dev/shm or "tmpfs."
To do this, the contents of the Pynamic build directory on /usr/common are copied by one rank on each compute node to /dev/shm and the
target directory is prepended to LD_LIBRARY_PATH.
The tmpfs results provide a useful baseline for measuring performance since they are about the best one could hope for.

The *tmpfs* configuration usually leads all the other configurations excluding *shifter* on Cori where it ties.

Some Discussion
---------------

The Pynamic benchmark has been deployed at NERSC on Edison and Cori and is being run regularly (once a day on each system) to gauge shared library performance.
In general Pynamic's performance measurement values look like:

    *tmpfs* (or *shifter* on Cori) < *common* < *project* and *scratch*
