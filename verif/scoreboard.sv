class Scoreboard;
  mailbox #(Packet) drv2scb;
  mailbox #(Result) mon2scb;
  int num_expected;
  int num_checked;
  Coverage cov;

  function new(mailbox #(Packet) drv2scb, mailbox #(Result) mon2scb, int num_expected);
    this.drv2scb = drv2scb;
    this.mon2scb = mon2scb;
    this.num_expected = num_expected;
    this.num_checked = 0;
    this.cov = new();
  endfunction

  function automatic logic [31:0] predict_lane(input vpu_op_e op, input logic [31:0] a, input logic [31:0] b);
    case (op)
      VPU_FADD: return sf_f32_add(a, b);
      VPU_FSUB: return sf_f32_sub(a, b);
      VPU_FMUL: return sf_f32_mul(a, b);
      default:  return '0;
    endcase
  endfunction

  function automatic vec_t predict(input Packet p);
    vec_t expected;
    for (int i = 0; i < NUM_LANES; i++) begin
      expected[i] = predict_lane(p.op_t, p.src0_data[i], p.src1_data[i]);
    end
    return expected;
  endfunction

  task run();
    Packet p;
    Result r;
    vec_t expected;
    bit data_pass;

    forever begin
      drv2scb.get(p);
      mon2scb.get(r);
      expected = predict(p);
      data_pass = 1'b1;

      if (r.vd !== p.vd) begin
        $error("VD mismatch: expected %0d got %0d", p.vd, r.vd);
        data_pass = 1'b0;
      end

      for (int i = 0; i < NUM_LANES; i++) begin
        if (r.data[i] !== expected[i]) begin
          $error("DATA mismatch lane %0d: expected %h got %h", i, expected[i], r.data[i]);
          data_pass = 1'b0;
        end
      end

      if (data_pass) begin
        $display("[SCB] PASS vd=%0d", r.vd);
      end

      cov.sample(p, r);
      num_checked++;

      if (num_checked == num_expected) begin
        $display("[SCB] Completed %0d checks", num_checked);
        cov.report();
        $finish;
      end
    end
  endtask
endclass
