#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v vcs >/dev/null 2>&1; then
  echo "VCS is not on PATH. On this server run: module load synopsys/synopsys-vcs" >&2
  exit 1
fi
if [[ ! -f cmodel/softfloat/source/include/softfloat.h ]]; then
  echo "SoftFloat is missing. Run: git submodule update --init --recursive" >&2
  exit 1
fi

mkdir -p build/vcs
make -C cmodel/softfloat/build/Linux-x86_64-GCC >build/vcs/softfloat_build.log 2>&1

vcs -full64 -sverilog -timescale=1ns/1ps -assert svaext \
  +incdir+verif +incdir+rtl -top top_tb -f verif/files.f \
  -CFLAGS "-I$PWD/cmodel/softfloat/source/include" \
  cmodel/softfloat_dpi.c \
  -LDFLAGS "-Wl,--whole-archive,$PWD/cmodel/softfloat/build/Linux-x86_64-GCC/softfloat.a,--no-whole-archive" \
  -Mdir=build/vcs/csrc -o "$PWD/build/vcs/simv" \
  -cm line+cond+tgl+fsm+branch+assert \
  -cm_dir "$PWD/build/vcs/coverage.vdb" -l build/vcs/compile.log

# Give each run its own coverage test name. Pass +TEST, +NUM_TESTS and
# +ntb_random_seed on the command line; all arguments go to the simulator.
run_name="${RUN_NAME:-run_$(date +%Y%m%d_%H%M%S)_$$}"
build/vcs/simv -cm line+cond+tgl+fsm+branch+assert \
  -cm_dir "$PWD/build/vcs/coverage.vdb" -cm_name "$run_name" \
  -l "build/vcs/${run_name}.log" "$@"

# VCS can return zero after $error (including assertion failures).
if grep -Eq '^(Error:|Fatal:)' "build/vcs/${run_name}.log" ||
   ! grep -q '\[SCB\] TEST PASS:' "build/vcs/${run_name}.log"; then
  echo "Test failed; see build/vcs/${run_name}.log" >&2
  exit 1
fi
