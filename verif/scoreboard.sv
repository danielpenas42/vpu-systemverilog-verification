class Scoreboard;
  mailbox #(Packet) drv2scb;
  mailbox #(Result) mon2scb;
  int num_expected;
  int num_checked;
  int num_failed;
  Coverage cov;

  function new(mailbox #(Packet) drv2scb, mailbox #(Result) mon2scb, int num_expected);
    this.drv2scb = drv2scb;
    this.mon2scb = mon2scb;
    this.num_expected = num_expected;
    this.num_checked = 0;
    this.num_failed = 0;
    this.cov = new();
  endfunction

  function automatic logic [31:0] predict_lane(input vpu_op_e op, input logic [31:0] a, input logic [31:0] b);
    logic [31:0] y;
    case (op)
      VPU_FADD: y = sf_f32_add(a, b);
      VPU_FSUB: y = sf_f32_sub(a, b);
      VPU_FMUL: y = sf_f32_mul(a, b);
      default:  $fatal(1, "Unsupported opcode %0d", op);
    endcase
    // The vendored FP32 units return a canonical quiet NaN, rather than
    // propagating the sign/payload as the SoftFloat 8086-SSE build does.
    if (y[30:23] == 8'hff && y[22:0] != 0) y = 32'h7fc00000;
    return y;
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
      end else begin
        num_failed++;
      end

      cov.sample(p, r);
      num_checked++;

      if (num_checked == num_expected) begin
        $display("[SCB] Completed %0d checks", num_checked);
        cov.report();
        if (num_failed != 0)
          $fatal(1, "[SCB] FAIL: %0d of %0d packets failed", num_failed, num_checked);
        $display("[SCB] TEST PASS: %0d packets, %0d lanes checked", num_checked, num_checked * NUM_LANES);
        $finish;
      end
    end
  endtask
endclass
