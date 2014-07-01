#
# Condor submission script for Phi calculation of a single transition table.
# Jory Schossau
# Adami Lab
#

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
INIT1=XINIT1X
INIT2=XINIT2X
INIT3=XINIT3X

universe = vanilla
 
executable = $(RUN_DIR)/$(PROGRAM)

# copy executable to machine
transfer_executable = true
 
# which files to copy back?
#transfer_output_files = $(outputFile)$(replicateID)_$(experimentVariable).phi
# transfer settings
should_transfer_files = YES
when_to_transfer_output = ON_EXIT

#output = $(INPUT_FILES).out
#error = $(INPUT_FILES).err
#log = $(INPUT_FILES).log
 
# location of input files (and where to put output files)
# in this example, we want each job to write the read and write data to a directory based on its job process
#initialdir = $(RUN_DIR)/$(DIR_PREFIX)_$(PROCESS)
initialdir = $(RUN_DIR)
 
# input files.
#transfer_input_files = $(INPUT_FILES)
 
run_as_owner = false
 
# system requirements
# if you only want to run on the windows condor cluster, you should list the folowing line
#requirements = (OpSys == "WINNT61") && (Arch == "X86_64") #only for XSEDE cluster
requirements = (OpSys == "WINNT51") && (Arch == "INTEL") #only for MSU cluster
 
arguments = XPMX $(OUTPUT_NAME).$(Process) $(GENERATIONS) $(LOCALMU) $(DELTAMU) $(INIT1) $(INIT2) $(INIT3)

queue $(RUNS)
