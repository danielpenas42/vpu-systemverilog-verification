#!/bin/zsh
set -e

cd "$(dirname "$0")"

make -C cmodel/softfloat/build/Linux-x86_64-GCC

verilator --binary --timing --top-module top_tb \
  -Iverif -Irtl \
  -CFLAGS "-I$PWD/cmodel/softfloat/source/include -I$PWD/cmodel/softfloat/source/8086-SSE" \
  -LDFLAGS "$PWD/cmodel/softfloat/build/Linux-x86_64-GCC/softfloat.a" \
  verif/vpu_pkg.sv \
  third_party/fp32-combinational-units/fp32_addsub.sv \
  third_party/fp32-combinational-units/fp32_add_comb.sv \
  third_party/fp32-combinational-units/fp32_sub_comb.sv \
  third_party/fp32-combinational-units/fp32_mul_comb.sv \
  rtl/fp32_alu.sv \
  rtl/vpu_lane.sv \
  rtl/vreg_file.sv \
  rtl/vpu.sv \
  verif/vpu_if.sv \
  verif/vrf_if.sv \
  verif/generator.sv \
  verif/driver.sv \
  verif/monitor.sv \
  verif/coverage.sv \
  verif/scoreboard.sv \
  verif/assertions.sv \
  verif/top_tb.sv \
  cmodel/softfloat_dpi.c

./obj_dir/Vtop_tb
