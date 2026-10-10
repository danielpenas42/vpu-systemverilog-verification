module top_tb();
    import vpu_pkg::*;

    localparam int NUM_TESTS = 100;

    logic      clk;
    logic      rst_n;

    initial begin
        clk = 0;
        rst_n = 0;
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
        Generator gen;
        Driver drv;
        Monitor mon;
        Scoreboard scb;

        gen2drv = new();
        drv2scb = new();
        mon2scb = new();

        gen = new(gen2drv, NUM_TESTS);
        drv = new(vif, load_if, gen2drv, drv2scb);
        mon = new(vif, mon2scb);
        scb = new(drv2scb, mon2scb, NUM_TESTS);

        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_none

        // timeout
        repeat (1000) @(posedge clk);
        $fatal("Test timeout");
    end
endmodule
