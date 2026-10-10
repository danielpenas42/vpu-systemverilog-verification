# fp32-combinational-units

Vendored subset of `adachi6k/fp32-combinational-units`.

Used files:
- `fp32_addsub.sv`
- `fp32_add_comb.sv`
- `fp32_sub_comb.sv`
- `fp32_mul_comb.sv`

These modules provide combinational IEEE-754 FP32 add, subtract, and multiply
datapaths. The VPU wraps them in `rtl/fp32_alu.sv` with a registered output to
keep the lane ALU latency at one cycle.

License: MIT. See `LICENSE`.
