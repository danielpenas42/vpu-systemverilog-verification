// Single-lane FP32 ALU. The operation datapaths are combinational IEEE-754
// units from third_party/fp32-combinational-units; this wrapper registers the
// selected result to keep the VPU lane at 1-cycle ALU latency.
module fp32_alu
  import vpu_pkg::*;
(
  input  logic              clk,
  input  logic              rst_n,
  input  vpu_op_e           op,
  input  logic [DATA_W-1:0] a,
  input  logic [DATA_W-1:0] b,
  output logic [DATA_W-1:0] y
);

  logic [31:0] add_y;
  logic [31:0] sub_y;
  logic [31:0] mul_y;

  logic add_exc_invalid, add_exc_divzero, add_exc_overflow, add_exc_underflow, add_exc_inexact;
  logic sub_exc_invalid, sub_exc_divzero, sub_exc_overflow, sub_exc_underflow, sub_exc_inexact;
  logic mul_exc_invalid, mul_exc_divzero, mul_exc_overflow, mul_exc_underflow, mul_exc_inexact;

  fp32_add_comb u_add (
    .a(a),
    .b(b),
    .exc_invalid(add_exc_invalid),
    .exc_divzero(add_exc_divzero),
    .exc_overflow(add_exc_overflow),
    .exc_underflow(add_exc_underflow),
    .exc_inexact(add_exc_inexact),
    .y(add_y)
  );

  fp32_sub_comb u_sub (
    .a(a),
    .b(b),
    .exc_invalid(sub_exc_invalid),
    .exc_divzero(sub_exc_divzero),
    .exc_overflow(sub_exc_overflow),
    .exc_underflow(sub_exc_underflow),
    .exc_inexact(sub_exc_inexact),
    .y(sub_y)
  );

  fp32_mul_comb u_mul (
    .a(a),
    .b(b),
    .exc_invalid(mul_exc_invalid),
    .exc_divzero(mul_exc_divzero),
    .exc_overflow(mul_exc_overflow),
    .exc_underflow(mul_exc_underflow),
    .exc_inexact(mul_exc_inexact),
    .y(mul_y)
  );

  logic [31:0] y_d;

  always_comb begin
    unique case (op)
      VPU_FADD: y_d = add_y;
      VPU_FSUB: y_d = sub_y;
      VPU_FMUL: y_d = mul_y;
      default:  y_d = '0;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      y <= '0;
    end else begin
      y <= y_d;
    end
  end
endmodule
