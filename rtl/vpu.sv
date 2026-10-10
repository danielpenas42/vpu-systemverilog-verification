// 16-lane FP32 VPU. Accepts an instruction, requests vs0/vs1 from a
// synchronous VRF, then registers the result for write-back to vd.
// Lane i operates on bits [32*i +: 32] of each 512-bit vreg.
module vpu
  import vpu_pkg::*;
(
  input  logic              clk,
  input  logic              rst_n,

  // instruction
  input  logic              in_valid,
  output logic              in_ready,
  input  vpu_op_e           in_opcode,
  input  logic [VIDX_W-1:0] in_vs0,
  input  logic [VIDX_W-1:0] in_vs1,
  input  logic [VIDX_W-1:0] in_vd,

  // VRF read ports
  output logic [VIDX_W-1:0] rd0_idx,
  input  logic [VEC_W-1:0]  rd0_data,
  output logic [VIDX_W-1:0] rd1_idx,
  input  logic [VEC_W-1:0]  rd1_data,

  // VRF write port
  output logic              wr_valid,
  input  logic              wr_ready,
  output logic [VIDX_W-1:0] wr_idx,
  output logic [VEC_W-1:0]  wr_data
);
  typedef enum logic [2:0] {
    S_IDLE,
    S_READ,
    S_ALU,
    S_EXEC,
    S_WB
  } state_e;

  state_e state_q;
  vpu_op_e op_q;
  logic [VIDX_W-1:0] vd_q;
  logic [VEC_W-1:0] lane_y;

  assign in_ready = (state_q == S_IDLE);

  for (genvar i = 0; i < NUM_LANES; i++) begin : g_lane
    vpu_lane u_lane (
      .clk(clk),
      .rst_n(rst_n),
      .op(op_q),
      .a (rd0_data[DATA_W*i +: DATA_W]),
      .b (rd1_data[DATA_W*i +: DATA_W]),
      .y (lane_y[DATA_W*i +: DATA_W])
    );
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q  <= S_IDLE;
      op_q     <= VPU_FADD;
      vd_q     <= '0;
      rd0_idx  <= '0;
      rd1_idx  <= '0;
      wr_valid <= 1'b0;
      wr_idx   <= '0;
      wr_data  <= '0;
    end else begin
      unique case (state_q)
        S_IDLE: begin
          wr_valid <= 1'b0;
          if (in_valid) begin
            rd0_idx <= in_vs0;
            rd1_idx <= in_vs1;
            op_q    <= in_opcode;
            vd_q    <= in_vd;
            state_q <= S_READ;
          end
        end

        S_READ: begin
          state_q <= S_ALU;
        end

        S_ALU: begin
          state_q <= S_EXEC;
        end

        S_EXEC: begin
          wr_valid <= 1'b1;
          wr_idx   <= vd_q;
          wr_data  <= lane_y;
          state_q  <= S_WB;
        end

        S_WB: begin
          if (wr_ready) begin
            wr_valid <= 1'b0;
            state_q  <= S_IDLE;
          end
        end

        default: begin
          wr_valid <= 1'b0;
          state_q  <= S_IDLE;
        end
      endcase
    end
  end
endmodule
