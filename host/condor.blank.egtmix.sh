#
# Condor submission script for Phi calculation of a single transition table.
# Jory Schossau
# Adami Lab
#

+ProjectName = "TG-IBN130008"

notification = Error
notify_user = joryschossau@gmail.com
 
getenv = True
# setting up some environment variables specific for this job
#PM= # set where used below

RUNS=XRUNSX
RUN_DIR=XRUNDIRX
OUTPUT_NAME=XOUTPUTNAMEX
GENERATIONS=XGENERATIONSX
PROGRAM=XPROGRAMX
#PERIOD=XPERIODX
LOCALMU=XLOCALMUX
DELTAMU=XDELTAMUX

universe = vanilla
 
# with two executables, you will be able to run on all execute hosts available at MSU
executable = $(RUN_DIR)/$(PROGRAM)

# copy executable to machine
transfer_executable = true
 
# which files to copy back?
#transfer_output_files = $(outputFile)$(replicateID)_$(experimentVariable).phi
# transfer settings
should_transfer_files = YES
when_to_transfer_output = ON_EXIT

output = $(PROGRAM).out
error = $(PROGRAM).err
log = $(PROGRAM).log
 
# location of input files (and where to put output files)
# in this example, we want each job to write the read and write data to a directory based on its job process
#initialdir = $(RUN_DIR)/$(DIR_PREFIX)_$(PROCESS)
initialdir = $(RUN_DIR)
 
# input files.
#transfer_input_files = $(INPUT_FILES)
 
run_as_owner = false
 
# system requirements
# if you only want to run on the windows condor cluster, you should list the folowing line
requirements = (OpSys == "LINUX") && (Arch == "X86_64")
#requirements = (OpSys == "WINNT61") && (Arch == "X86_64")
#requirements = (OpSys == "WINNT51") && (Arch == "INTEL")
 
arguments = XPMX $(OUTPUT_NAME).$(Process) $(GENERATIONS) $(LOCALMU) $(DELTAMU)

queue $(RUNS)
