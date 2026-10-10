interface vpu_if (input logic clk, input logic rst_n);
  import vpu_pkg::*;
  // instruction
  logic              in_valid, in_ready;
  vpu_op_e           in_opcode;
  logic [VIDX_W-1:0] in_vs0, in_vs1, in_vd;
  // VRF read ports
  logic [VIDX_W-1:0] rd0_idx, rd1_idx;
  logic [VEC_W-1:0]  rd0_data, rd1_data;
  // VRF write port
  logic              wr_valid, wr_ready;
  logic [VIDX_W-1:0] wr_idx;
  logic [VEC_W-1:0]  wr_data;

  clocking cb @(posedge clk);
    inout in_valid;
    input in_ready;
    inout in_opcode;
    inout in_vs0;
    inout in_vs1;
    inout in_vd;
    input rd0_idx;
    input rd1_idx;
    input rd0_data;
    input rd1_data;
    input wr_valid;
    inout wr_ready;
    input wr_idx;
    input wr_data;
  endclocking
endinterface

