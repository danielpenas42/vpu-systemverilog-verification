module vpu_lane
  import vpu_pkg::*;
(
  input  logic              clk,
  input  logic              rst_n,
  input  vpu_op_e           op,
  input  logic [DATA_W-1:0] a,
  input  logic [DATA_W-1:0] b,
  output logic [DATA_W-1:0] y
);
  fp32_alu u_alu (.clk(clk), .rst_n(rst_n), .op(op), .a(a), .b(b), .y(y));
endmodule
