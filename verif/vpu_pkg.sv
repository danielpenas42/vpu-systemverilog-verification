package vpu_pkg;
  localparam int NUM_LANES = 16;
  localparam int DATA_W    = 32;                 // FP32
  localparam int VEC_W     = NUM_LANES * DATA_W; // 512
  localparam int NUM_VREGS = 32;
  localparam int VIDX_W    = $clog2(NUM_VREGS);  // 5
  localparam int VPU_ACCEPT_TO_WB_LATENCY = 3;

  typedef enum logic [1:0] {
    VPU_FADD = 2'd0,
    VPU_FSUB = 2'd1,
    VPU_FMUL = 2'd2
  } vpu_op_e;

  typedef logic [NUM_LANES-1:0][DATA_W-1:0] vec_t;
  typedef logic [VIDX_W-1:0]                vreg_idx_t;

  typedef enum int {
    FP32_POS_ZERO,
    FP32_NEG_ZERO,
    FP32_POS_INF,
    FP32_NEG_INF,
    FP32_POS_NAN,
    FP32_NEG_NAN,
    FP32_SUBNORMAL,
    FP32_NORMAL
  } fp32_category_t;

  function automatic fp32_category_t fp32_category(input logic [31:0] x);
    if (x == 32'h00000000) return FP32_POS_ZERO;
    if (x == 32'h80000000) return FP32_NEG_ZERO;

    if (x == 32'h7F800000) return FP32_POS_INF;
    if (x == 32'hFF800000) return FP32_NEG_INF;

    if ((x[30:23] == 8'hFF) && (x[22:0] != 23'h0)) begin
      return x[31] ? FP32_NEG_NAN : FP32_POS_NAN;
    end

    if ((x[30:23] == 8'h00) && (x[22:0] != 23'h0)) begin
      return FP32_SUBNORMAL;
    end

    return FP32_NORMAL;
  endfunction

  import "DPI-C" function int unsigned sf_f32_add(input int unsigned a,
                                                   input int unsigned b);
  import "DPI-C" function int unsigned sf_f32_sub(input int unsigned a,
                                                   input int unsigned b);
  import "DPI-C" function int unsigned sf_f32_mul(input int unsigned a,
                                                   input int unsigned b);

  class Packet;
    rand vpu_op_e op_t;

    rand vreg_idx_t vs0;
    rand vreg_idx_t vs1;
    rand vreg_idx_t vd;

    rand vec_t    src0_data;
    rand vec_t    src1_data;

    constraint valid_op {
      op_t inside {VPU_FADD, VPU_FSUB, VPU_FMUL};
    }

    constraint no_overlap {
      vs0 != vs1;
      vs0 != vd;
      vs1 != vd;
    }

    function void display(string tag = "PKT");
      $display("[%s] op=%0d vs0=%0d vs1=%0d vd=%0d",
             tag, op_t, vs0, vs1, vd);
    endfunction

  endclass

class Result;
  vreg_idx_t vd;
  vec_t data;

  function void display(string tag = "RESULT");
    $display("[%s] vd=%0d", tag, vd);
  endfunction
endclass


endpackage
