// STAND-IN vector register file: 32 x 512b, 2 sync read ports, 1 sync write port.
module vreg_file
  import vpu_pkg::*;
(
  input  logic                clk,
  input  logic                tb_load0_en,
  input  logic [VIDX_W-1:0]   tb_load0_idx,
  input  logic [VEC_W-1:0]    tb_load0_data,
  input  logic                tb_load1_en,
  input  logic [VIDX_W-1:0]   tb_load1_idx,
  input  logic [VEC_W-1:0]    tb_load1_data,
  input  logic                wr_en,
  input  logic [VIDX_W-1:0]   wr_idx,
  input  logic [VEC_W-1:0]    wr_data,
  input  logic [VIDX_W-1:0]   rd0_idx,
  output logic [VEC_W-1:0]    rd0_data,
  input  logic [VIDX_W-1:0]   rd1_idx,
  output logic [VEC_W-1:0]    rd1_data


);
  logic [VEC_W-1:0] regs [NUM_VREGS];

  always_ff @(posedge clk) begin
    rd0_data <= regs[rd0_idx];
    rd1_data <= regs[rd1_idx];

    assert (!((tb_load0_en || tb_load1_en) && wr_en))
      else $error("VRF testbench load overlaps with VPU writeback");
    assert (!(tb_load0_en && tb_load1_en && (tb_load0_idx == tb_load1_idx)))
      else $error("VRF testbench load0/load1 target the same register");

    if (tb_load0_en) regs[tb_load0_idx] <= tb_load0_data;
    if (tb_load1_en) regs[tb_load1_idx] <= tb_load1_data;
    if (!(tb_load0_en || tb_load1_en) && wr_en) regs[wr_idx] <= wr_data;
  end
endmodule
