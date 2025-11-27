
# Script for Running NCCL Tests

## Prerequisites
- **NCCL** version >= 2.27  
- **nccl-test** version >= 2.17.6  

## Build Instructions
1. Clone or navigate to the `nccl-tests` directory.
2. Compile the test suite with MPI support:
```bash	
$ make MPI=1 MPI_HOME=/path/to/mpi CUDA_HOME=/path/to/cuda NCCL_HOME=/path/to/nccl
```

## Running the Test Script
1. Copy script `test.sh` into the root of the `nccl-tests` directory.
2. Execute the script.
> ⏱️ **Expected runtime**: 30–60 minutes, depending on your system and configuration.

### Script Options
- `-P <path>`: Specify LD_PRELOAD path to load specific NCCL library (optional)
- Default usage: `./test.sh`
- With custom NCCL: `./test.sh -P /path/to/libnccl.so`

## Output
All test results and logs will be saved in the following directory:  
```
./nccl-tests/data/
```

Make sure you have write permissions in the `nccl-tests` directory before running the script.


