#!/usr/bin/env bash

# Usage: ./test.sh [-P LD_PRELOAD_PATH] [executable] [log_basename]
#
# -P LD_PRELOAD_PATH: path to add to LD_LIBRARY_PATH for LD_PRELOAD (optional)
# executable: name of the binary under ./build to run (default: alltoall_perf,all_reduce_perf)
# log_basename: prefix for log files under data/ (default: nccl)

set -eu -o pipefail

# Parse command line arguments
LD_PRELOAD_PATH=""  # Default path
EXE_NAME="alltoall_perf,all_reduce_perf"
LOG_BASE="nccl"

# Parse arguments
EXE_SET=""
LOG_SET=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -P)
            LD_PRELOAD_PATH="$2"
            shift 2
            ;;
        *)
            # If not -P option, treat as positional argument
            if [[ -z "$EXE_SET" ]]; then
                EXE_NAME="$1"
                EXE_SET=1
            elif [[ -z "$LOG_SET" ]]; then
                LOG_BASE="$1"
                LOG_SET=1
            fi
            shift
            ;;
    esac
done

BUILD_DIR="./build"
DATA_DIR="data"

# Split executables by comma if multiple are provided
IFS=',' read -ra EXECUTABLES <<< "$EXE_NAME"

mkdir -p "$DATA_DIR"

# Check all executables exist
for exe in "${EXECUTABLES[@]}"; do
	EXE_PATH="$BUILD_DIR/$exe"
	if [[ ! -x "$EXE_PATH" ]]; then
		echo "Error: executable '$EXE_PATH' not found or not executable." >&2
		echo "Build it first (e.g. run 'make' in the repository root) or pass a different executable name." >&2
		exit 2
	fi
done

# Helper to run mpirun and write logs. Args: executable, np, R, suffix
run_and_log() {
	local exe="$1"; shift
	local np="$1"; shift
	local R="$1"; shift
	local suffix="$1"; shift

	local EXE_PATH="$BUILD_DIR/$exe"
	local logname="$DATA_DIR/${LOG_BASE}-v100x${np}.${suffix}.${exe}.log"

	echo "Running: mpirun -np ${np} ${EXE_PATH} -R ${R} -b 8 -e 4G -G 100 -f 2 -n 100 -w 25 -g 1"
	if [[ -n "$LD_PRELOAD_PATH" ]]; then
		mpirun --bind-to core --map-by core --report-bindings -np "$np" -x LD_LIBRARY_PATH=${LD_PRELOAD_PATH}:${LD_LIBRARY_PATH:-} "$EXE_PATH" -R "$R" -b 8 -e 4G -G 100 -f 2 -n 100 -w 25 -g 1 | tee "$logname"
	else
		mpirun --bind-to core --map-by core --report-bindings -np "$np" -x LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-} "$EXE_PATH" -R "$R" -b 8 -e 4G -G 100 -f 2 -n 100 -w 25 -g 1 | tee "$logname"
	fi
}

# Runs: symmetric (R=2) with 2 and 4 procs, then local (R=1) with 2 and 4 procs
# for each executable (alltoall_perf and all_reduce_perf by default)
export NCCL_DEBUG=VERSION
for exe in "${EXECUTABLES[@]}"; do
	echo "=== Running tests for $exe ==="
	run_and_log "$exe" 2 2 symm
	run_and_log "$exe" 4 2 symm
	run_and_log "$exe" 2 1 local
	run_and_log "$exe" 4 1 local
done

echo "Logs written to: $DATA_DIR/"
