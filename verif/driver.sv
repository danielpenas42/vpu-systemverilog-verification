
import vpu_pkg::*;

class Driver;
    virtual vpu_if      vpu_vif;
    virtual vrf_if      vrf_vif;
    mailbox #(Packet) gen2drv;
    mailbox #(Packet) drv2scb;

    function new(virtual vpu_if vpu_vif,
                 virtual vrf_if vrf_vif,
                 mailbox #(Packet) gen2drv,
                 mailbox #(Packet) drv2scb);
        this.vpu_vif = vpu_vif;
        this.gen2drv = gen2drv;
        this.vrf_vif = vrf_vif;
        this.drv2scb = drv2scb;
    endfunction
    
    task init();
        vpu_vif.cb.in_valid <= 1'b0;
        vrf_vif.cb.load0_en <= 1'b0;
        vrf_vif.cb.load1_en <= 1'b0;
        @(vpu_vif.cb);
    endtask
    
    task run();
        Packet p;
        init();
        forever begin
            gen2drv.get(p);
            drive(p);
            drv2scb.put(p);
        end
    endtask

    task drive(Packet p);
        
        do @(vpu_vif.cb);
        while (!vpu_vif.cb.in_ready || vpu_vif.cb.wr_valid);
        // Drive operand preload and instruction in the same cycle.
        vrf_vif.cb.load0_en   <= 1'b1;
        vrf_vif.cb.load0_idx  <= p.vs0;
        vrf_vif.cb.load0_data <= p.src0_data;

        vrf_vif.cb.load1_en   <= 1'b1;
        vrf_vif.cb.load1_idx  <= p.vs1;
        vrf_vif.cb.load1_data <= p.src1_data;

        vpu_vif.cb.in_valid   <= 1'b1;
        vpu_vif.cb.in_opcode  <= p.op_t;
        vpu_vif.cb.in_vs0     <= p.vs0;
        vpu_vif.cb.in_vs1     <= p.vs1;
        vpu_vif.cb.in_vd      <= p.vd;

        @(vpu_vif.cb);

        // Drop enables so the dut can request data
        vrf_vif.cb.load0_en <= 1'b0;
        vrf_vif.cb.load1_en <= 1'b0;
        vpu_vif.cb.in_valid <= 1'b0;


    endtask

endclass
