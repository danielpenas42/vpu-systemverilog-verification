import vpu_pkg::*;

class Generator;
    mailbox #(Packet) gen2drv;
    int num_packets;


    function new(mailbox #(Packet) gen2drv, int num_packets);
        this.gen2drv = gen2drv;
        this.num_packets = num_packets;
    endfunction

    task run();
        Packet p;

        repeat (num_packets) begin
        p = new();

        if (p.randomize() == 0) begin
            $fatal("Packet randomization failed");
        end

        p.display("GEN");
        gen2drv.put(p);
        end
    endtask
endclass
