#!/usr/bin/env python

import  datetime
import  sys

class PynamicRun ( object ) :

    def __init__( self, output_path ) :
        self.output_path = output_path
        self._parse_output_path()
        self._parse_output_content()

    def _parse_output_path( self ) :
        tokens = self.output_path[ : -4 ].split( "-" )
        self.host       = tokens[ 1 ]
        self.filesystem = tokens[ 4 ]
        self.job_id     = int( tokens[ 5 ] )

    def _parse_output_content( self ) :
        times = list()
        for line in self._output_content() :
            if line.startswith( "Pynamic: run on" ) :
                tokens = line.split()
                date, time, size = [ tokens[ i ] for i in [ 3, 4, 6 ] ]
            if line.startswith( "Pynamic:" ) and line.find( "time" ) >= 0 :
                times.append( float( line.split()[ -2 ] ) )
            if line.find( "LD_DEBUG=libs" ) >= 0 :
                break
        self.executed     = datetime.datetime.strptime( " ".join( [ date, time ] ), "%x %X" )
        self.mpi_size     = int( size )
        self.startup_time = times[ 0 ]
        self.import_time  = times[ 1 ]
        self.visit_time   = times[ 2 ]
        self.compute_time = times[ 3 ] 
        self.total_time   = sum( times )

    def _output_content( self ) :
        with open( self.output_path, "r" ) as stream :
            return list( stream )

    def __repr__( self ) :
        result = "{:<10} {:<10} {:<10} {:<20} {:<5} {:8.2f} {:8.2f} {:8.2f} {:8.2f} {:8.2f}".format( self.host, 
                self.filesystem, self.job_id, self.executed.isoformat(), self.mpi_size, self.startup_time, 
                self.import_time, self.visit_time, self.compute_time, self.total_time )
        if self.executed.date() == datetime.date.today() :
            result = "\033[1m" + result + "\033[0m"
        return result

    def __cmp__( self, other ) :
        if self.host < other.host :
            return -1 
        if self.host > other.host :
            return +1
        if self.filesystem < other.filesystem :
            return -1
        if self.filesystem > other.filesystem :
            return +1
        if self.executed < other.executed :
            return -1
        if self.executed > other.executed :
            return +1
        return 0

if __name__ == "__main__" :

    import argparse
    import os
    import time

    parser = argparse.ArgumentParser()
    parser.add_argument( "output_paths", help = "list of output paths to parse", nargs  = "+"          )
    parser.add_argument( "--sum" , "-s", help = "print sum only"               , action = "store_true" )
    args = parser.parse_args()

    pynamic_runs = list()
    for path in args.output_paths :
        try :
            pynamic_runs.append( PynamicRun( path ) )
        except :
            cdate = datetime.date.fromtimestamp( os.path.getctime( path ) )
            message = "[WARNING] Unable to parse {} (created {})".format( path, cdate.isoformat() )
            if cdate == datetime.date.today() :
                message = "\033[1m\033[91m" + message + "\033[0m\033[0m"
            sys.stderr.write( "{}\n".format( message ) )
            pass

    for run in sorted( pynamic_runs ) :
        print run


### records = list()
### for filename in sys.argv[ 1 : ] :
###     with open( filename, "r" ) as stream :
###         times = list()
###         for line in stream :
###             if line.startswith( "Pynamic: run on" ) :
###                 tokens = line.split()
###                 dt     = datetime.datetime.strptime( " ".join( tokens[ 3 : 5 ] ), "%x %X" )
###                 size   = tokens[ 6 ]
###             if line.startswith( "Pynamic:" ) and line.find( "time" ) >= 0 :
###                 times.append( float( line.split()[ -2 ] ) )
###             if line.find( "mpi test passed" ) >= 0 :
###                 break
###         total = 0.0
###         try :
###             for i in range( 4 ) :
###                 total += times[ i ]
###             records.append( ( filename, dt, size, times[ 0 ], times[ 1 ], times[ 2 ], times[ 3 ], total ) )
###         except :
###             pass
### 
### for record in sorted( records, key = lambda r : r[ 1 ] ) :
###     print "%srecord
### 
