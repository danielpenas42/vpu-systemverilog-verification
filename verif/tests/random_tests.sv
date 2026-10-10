import vpu_pkg::*;

class RandomMixedTest;
  mailbox #(Packet) gen2drv;
  int num_packets;

  function new(mailbox #(Packet) gen2drv, int num_packets);
    this.gen2drv = gen2drv;
    this.num_packets = num_packets;
  endfunction

  task run();
    Packet p;
    MixedSpecialPacket mixed_p;

    repeat (num_packets) begin
      mixed_p = new();
      if (mixed_p.randomize() == 0) begin
        $fatal("MixedSpecialPacket randomization failed");
      end

      p = mixed_p;
      p.display("RANDOM_MIXED");
      gen2drv.put(p);
    end
  endtask
endclass

class RandomBaseTest;
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

      p.display("RANDOM_BASE");
      gen2drv.put(p);
    end
  endtask
endclass
