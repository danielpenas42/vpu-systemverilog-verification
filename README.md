# FP32 VPU Verification Project

This started as a small VPU project that I had worked on before. I came back to
it because I wanted to learn how a more complete SystemVerilog verification
environment fits together instead of only writing directed testbenches.

The DUT is a 16-lane FP32 vector processing unit with a 32-entry vector register
file. The verification side now has randomized packet classes, mailboxes, a
driver and monitor, a scoreboard using SoftFloat, functional coverage, and some
SystemVerilog assertions. It has been really cool to see how all of these pieces
work together and how coverage can point out cases that random testing missed.

## What the VPU Does

The DUT accepts a vector instruction with:

- `op`: FP32 add, subtract, or multiply
- `vs0`: source vector register 0
- `vs1`: source vector register 1
- `vd`: destination vector register

The VPU reads `vs0` and `vs1` from the vector register file, runs the FP32
operation lane-by-lane, and writes the result vector back to `vd`.

Each vector contains 16 FP32 lanes:

```systemverilog
typedef logic [NUM_LANES-1:0][DATA_W-1:0] vec_t;
```

So `vec[i]` gives one 32-bit FP32 lane.

## RTL

- `rtl/vpu.sv`: top-level VPU FSM
- `rtl/vpu_lane.sv`: one FP32 lane wrapper
- `rtl/fp32_alu.sv`: one-cycle registered FP32 ALU wrapper
- `rtl/vreg_file.sv`: vector register file with testbench preload ports

The FP32 datapaths come from a small open-source RTL subset of
`adachi6k/fp32-combinational-units`:

- `third_party/fp32-combinational-units/fp32_addsub.sv`
- `third_party/fp32-combinational-units/fp32_add_comb.sv`
- `third_party/fp32-combinational-units/fp32_sub_comb.sv`
- `third_party/fp32-combinational-units/fp32_mul_comb.sv`

Those modules are combinational. `rtl/fp32_alu.sv` wraps them and registers the
selected result, so the VPU still sees a one-cycle ALU latency.

## Verification Environment

- `verif/vpu_pkg.sv`: shared constants, typedefs, packet/result classes, DPI imports
- `verif/vpu_if.sv`: VPU instruction/writeback interface
- `verif/vrf_if.sv`: testbench preload interface for the vector register file
- `verif/generator.sv`: creates randomized packets and sends them to the driver
- `verif/driver.sv`: preloads operands into the VRF and drives instructions
- `verif/monitor.sv`: observes accepted writebacks
- `verif/scoreboard.sv`: compares DUT results against SoftFloat DPI predictions
- `verif/coverage.sv`: functional coverage for ops, registers, FP categories, and crosses
- `verif/assertions.sv`: protocol assertions for writeback behavior
- `verif/packets/packet_lib.sv`: child packet classes for targeted random testing
- `verif/tests/`: directed and random test classes

## Reference Model

The scoreboard uses Berkeley SoftFloat through DPI-C:

- `cmodel/softfloat/`: SoftFloat source
- `cmodel/softfloat_dpi.c`: small C wrapper for `f32_add`, `f32_sub`, and `f32_mul`

That lets the scoreboard compare each 32-bit FP32 lane against the software
model. The vendored RTL always returns `0x7fc00000` for a NaN result, so the
scoreboard converts SoftFloat's NaN predictions to that same encoding before
the bit-for-bit comparison. Other results, including signed zero, are compared
without conversion. The VPU interface does not expose FP exception flags.

## Running the Tests

These commands assume VCS has already been set up in your shell. From the
repository directory, initialize the SoftFloat submodule once:

```sh
git submodule update --init --recursive
```

Then run whichever test you want:

```sh
./run_vcs_softfloat.sh +TEST=base     +NUM_TESTS=100 +ntb_random_seed=1
./run_vcs_softfloat.sh +TEST=mixed +NUM_TESTS=100 +ntb_random_seed=1
./run_vcs_softfloat.sh +TEST=directed                +ntb_random_seed=1
./run_vcs_softfloat.sh +TEST=all      +NUM_TESTS=100 +ntb_random_seed=1
```

- `base` uses unrestricted random FP32 operands.
- `mixed` gives more weight to zeros, infinities, NaNs, subnormals, and normal
  values so useful combinations are reached faster.
- `directed` runs the six targeted packet classes.
- `all` runs base, mixed, and directed in that order.

`NUM_TESTS` controls the number of packets in both the base and mixed phases.
For example, `TEST=all` with `NUM_TESTS=100` sends 206 packets: 100 base, 100
mixed, and six directed. Setting the random seed makes a run repeatable on the
same simulator version.

The runner builds SoftFloat, compiles the files in `verif/files.f`, and runs the
selected test. A successful run ends with `[SCB] TEST PASS`. Logs are saved
under `build/vcs/`.

## Coverage

Coverage accumulates as separately named runs in `build/vcs/coverage.vdb`.
I use `RUN_NAME` to keep runs separate:

```sh
RUN_NAME=all_seed1 ./run_vcs_softfloat.sh \
  +TEST=all +NUM_TESTS=100 +ntb_random_seed=1
```

Generate the HTML report with:

```sh
urg -dir build/vcs/coverage.vdb -report build/vcs/coverage_report
```

Open `build/vcs/coverage_report/dashboard.html` to inspect code, assertion, and
functional coverage.

The covergroup samples all 16 lanes, so each vector packet contributes 16
matched source/result samples. Negative-NaN inputs are still covered, but a
negative-NaN result is ignored because this RTL always returns the positive
canonical NaN value `0x7fc00000`.

My larger run used 10,000 packets for each random phase. It checked 20,006
packets and 320,096 lanes, and it reached every functional bin that is possible
for this design.

## What I Was Practicing

This project helped me practice:

- SystemVerilog interfaces and clocking blocks
- generator/driver/monitor/scoreboard structure
- mailboxes for communication between testbench components
- constrained random packet classes and child packet specialization
- functional coverage and coverage-driven test planning
- SystemVerilog assertions for valid/ready-style protocol behavior
- DPI-C integration with a real software reference model
- debugging coverage holes instead of only increasing the random test count

There is still more I would like to try, especially writeback backpressure,
reset during an active operation, and directed cases for rare FP32 rounding
paths. Those areas show why a high functional coverage number does not
automatically mean every code path has been tested.

## Third-Party Code

The FP32 arithmetic modules under `third_party/` come from the
`adachi6k/fp32-combinational-units` project. Berkeley SoftFloat is included as a
Git submodule under `cmodel/softfloat/`. Their original license files and
copyright notices are kept with the source.
