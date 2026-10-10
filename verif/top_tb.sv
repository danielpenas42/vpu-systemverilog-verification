module top_tb();
    import vpu_pkg::*;

    int num_tests = 100;
    int total_packets;
    string test_name = "base";

    logic      clk;
    logic      rst_n;

    initial begin
        clk = 0;
        rst_n = 0;
        vif.in_valid = 0;
        load_if.load0_en = 0;
        load_if.load1_en = 0;
    end

    always begin
        #5 clk = ~clk;
    end

    vrf_if load_if(clk);
    vpu_if vif(clk, rst_n);
    mailbox #(Packet) gen2drv;
    mailbox #(Packet) drv2scb;
    mailbox #(Result) mon2scb;

    assign vif.wr_ready = 1'b1;

    vpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(vif.in_valid),
        .in_ready(vif.in_ready),
        .in_opcode(vif.in_opcode),
        .in_vs0(vif.in_vs0),
        .in_vs1(vif.in_vs1),
        .in_vd(vif.in_vd),
        .rd0_idx(vif.rd0_idx),
        .rd0_data(vif.rd0_data),
        .rd1_idx(vif.rd1_idx),
        .rd1_data(vif.rd1_data),
        .wr_valid(vif.wr_valid),
        .wr_ready(vif.wr_ready),
        .wr_idx(vif.wr_idx),
        .wr_data(vif.wr_data)
    );

    vreg_file vrf (
        .clk(clk),
        .tb_load0_en(load_if.load0_en),
        .tb_load0_idx(load_if.load0_idx),
        .tb_load0_data(load_if.load0_data),
        .tb_load1_en(load_if.load1_en),
        .tb_load1_idx(load_if.load1_idx),
        .tb_load1_data(load_if.load1_data),
        .wr_en(vif.wr_valid && vif.wr_ready),
        .wr_idx(vif.wr_idx),
        .wr_data(vif.wr_data),
        .rd0_idx(vif.rd0_idx),
        .rd0_data(vif.rd0_data),
        .rd1_idx(vif.rd1_idx),
        .rd1_data(vif.rd1_data)
    );

    vpu_assertions vpu_assertions_i (
        .clk(clk),
        .rst_n(rst_n),
        .wr_valid(vif.wr_valid),
        .wr_ready(vif.wr_ready),
        .wr_idx(vif.wr_idx),
        .wr_data(vif.wr_data)
    );

    initial begin
        RandomBaseTest base_test;
        RandomMixedTest mixed_test;
        DirectedEdgeTest directed_test;
        Driver drv;
        Monitor mon;
        Scoreboard scb;

        gen2drv = new();
        drv2scb = new();
        mon2scb = new();

        if (!$value$plusargs("TEST=%s", test_name)) test_name = "base";
        if (!$value$plusargs("NUM_TESTS=%d", num_tests)) num_tests = 100;

        if (!(test_name inside {"base", "mixed", "directed", "all"}))
            $fatal(1, "Choose TEST=base, mixed, directed, or all");
        if (test_name == "directed") num_tests = 6;
        if (num_tests <= 0) $fatal(1, "NUM_TESTS must be positive");
        total_packets = (test_name == "all") ? 2 * num_tests + 6 : num_tests;
        $display("[TB] TEST=%s NUM_TESTS=%0d TOTAL_PACKETS=%0d",
                 test_name, num_tests, total_packets);

        drv = new(vif, load_if, gen2drv, drv2scb);
        mon = new(vif, mon2scb);
        scb = new(drv2scb, mon2scb, total_packets);

        rst_n = 0;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        fork
            begin
                if (test_name inside {"base", "all"}) begin
                    $display("[TB] Running base");
                    base_test = new(gen2drv, num_tests);
                    base_test.run();
                    if (test_name == "all") wait (scb.num_checked == num_tests);
                end
                if (test_name inside {"mixed", "all"}) begin
                    $display("[TB] Running mixed");
                    mixed_test = new(gen2drv, num_tests);
                    mixed_test.run();
                    if (test_name == "all") wait (scb.num_checked == 2 * num_tests);
                end
                if (test_name inside {"directed", "all"}) begin
                    $display("[TB] Running directed");
                    directed_test = new(gen2drv);
                    directed_test.run();
                end
            end
            drv.run();
            mon.run();
            scb.run();
        join_none

        // timeout
        repeat (20 * total_packets + 100) @(posedge clk);
        $fatal(1, "Test timeout");
    end
endmodule
