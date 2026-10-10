import vpu_pkg::*;

class Coverage;
  Packet p;
  fp32_category_t src0_cat;
  fp32_category_t src1_cat;
  fp32_category_t result_cat;

  covergroup vpu_cg;
    option.per_instance = 1;

    op_cp: coverpoint p.op_t {
      bins add = {VPU_FADD};
      bins sub = {VPU_FSUB};
      bins mul = {VPU_FMUL};
    }

    vd_cp: coverpoint p.vd {
      bins regs[] = {[0:NUM_VREGS-1]};
    }

    src0_cat_cp: coverpoint src0_cat {
      bins pos_zero  = {FP32_POS_ZERO};
      bins neg_zero  = {FP32_NEG_ZERO};
      bins pos_inf   = {FP32_POS_INF};
      bins neg_inf   = {FP32_NEG_INF};
      bins pos_nan   = {FP32_POS_NAN};
      bins neg_nan   = {FP32_NEG_NAN};
      bins subnormal = {FP32_SUBNORMAL};
      bins normal    = {FP32_NORMAL};
    }

    src1_cat_cp: coverpoint src1_cat {
      bins pos_zero  = {FP32_POS_ZERO};
      bins neg_zero  = {FP32_NEG_ZERO};
      bins pos_inf   = {FP32_POS_INF};
      bins neg_inf   = {FP32_NEG_INF};
      bins pos_nan   = {FP32_POS_NAN};
      bins neg_nan   = {FP32_NEG_NAN};
      bins subnormal = {FP32_SUBNORMAL};
      bins normal    = {FP32_NORMAL};
    }

    result_cat_cp: coverpoint result_cat {
      bins pos_zero  = {FP32_POS_ZERO};
      bins neg_zero  = {FP32_NEG_ZERO};
      bins pos_inf   = {FP32_POS_INF};
      bins neg_inf   = {FP32_NEG_INF};
      bins pos_nan   = {FP32_POS_NAN};
      bins subnormal = {FP32_SUBNORMAL};
      bins normal    = {FP32_NORMAL};
      ignore_bins neg_nan = {FP32_NEG_NAN};
    }

    op_x_vd:       cross op_cp, vd_cp;
    src0_x_src1:   cross src0_cat_cp, src1_cat_cp;
    op_x_result:   cross op_cp, result_cat_cp;
  endgroup

  function new();
    vpu_cg = new();
  endfunction

  function void sample(Packet pkt, Result res);
    p = pkt;
    foreach (pkt.src0_data[lane]) begin
      src0_cat = fp32_category(pkt.src0_data[lane]);
      src1_cat = fp32_category(pkt.src1_data[lane]);
      result_cat = fp32_category(res.data[lane]);
      vpu_cg.sample();
    end
  endfunction

  function void report();
    $display("[COV] vpu_cg coverage = %0.2f%%", vpu_cg.get_coverage());
  endfunction
endclass
