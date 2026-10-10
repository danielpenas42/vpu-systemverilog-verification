# VPU Verification Project

This is a VPU project I had worked on before and wanted to expand into a more
complete SystemVerilog verification environment. The design is a small FP32
vector processing unit with a vector register file. I used it as a way to
practice more realistic verification ideas instead of only writing simple
directed testbenches.

The main things I expanded were the class-based testbench structure, randomized
packets, mailboxes between components, a scoreboard with a SoftFloat reference
model, functional coverage, and a few SystemVerilog assertions. For the FP32
arithmetic itself, I used open-source RTL from the internet that already had
SoftFloat-backed testing, so the focus of this project could stay on the VPU
integration and verification environment.

## What It Does

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

## Testbench

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

That lets the scoreboard compare each 32-bit FP32 lane bit-for-bit against a
known-good software model.

## Running Tests

Use:

```sh
./run_verilator_softfloat.sh
```

This script does three main things:

1. Builds the local SoftFloat static library.
2. Compiles the RTL, verification files, DPI wrapper, and vendored FP32 units
   with Verilator.
3. Runs `top_tb`.

On my local machine, the full Verilator C++ build may fail with a missing
`<cstddef>` standard-library header. The SystemVerilog lint path passes, so that
failure is a local C++ toolchain issue rather than an RTL integration issue.

## What I Was Practicing

The goal was not only to make the VPU run, but to practice verification pieces
that show up in larger environments:

- clean SystemVerilog interfaces and clocking blocks
- generator/driver/monitor/scoreboard structure
- mailboxes for communication between testbench components
- constrained random packet classes and child packet specialization
- functional coverage and coverage-driven test planning
- SystemVerilog assertions for valid/ready-style protocol behavior
- DPI-C integration with a real software reference model
- integrating known-good open-source FP32 RTL into the VPU datapath
