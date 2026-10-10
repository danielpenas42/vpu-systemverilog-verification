import vpu_pkg::*;

class DirectedEdgeTest;
  mailbox #(Packet) gen2drv;

  function new(mailbox #(Packet) gen2drv);
    this.gen2drv = gen2drv;
  endfunction

  task put_normal();
    NormalPacket p;
    p = new();
    if (p.randomize() == 0) $fatal("NormalPacket randomization failed");
    p.display("DIRECTED_NORMAL");
    gen2drv.put(p);
  endtask

  task put_zero();
    ZeroPacket p;
    p = new();
    if (p.randomize() == 0) $fatal("ZeroPacket randomization failed");
    p.display("DIRECTED_ZERO");
    gen2drv.put(p);
  endtask

  task put_inf();
    InfPacket p;
    p = new();
    if (p.randomize() == 0) $fatal("InfPacket randomization failed");
    p.display("DIRECTED_INF");
    gen2drv.put(p);
  endtask

  task put_nan();
    NanPacket p;
    p = new();
    if (p.randomize() == 0) $fatal("NanPacket randomization failed");
    p.display("DIRECTED_NAN");
    gen2drv.put(p);
  endtask

  task put_subnormal();
    SubnormalPacket p;
    p = new();
    if (p.randomize() == 0) $fatal("SubnormalPacket randomization failed");
    p.display("DIRECTED_SUBNORMAL");
    gen2drv.put(p);
  endtask

  task put_overflow();
    OverflowPacket p;
    p = new();
    if (p.randomize() == 0) $fatal("OverflowPacket randomization failed");
    p.display("DIRECTED_OVERFLOW");
    gen2drv.put(p);
  endtask

  task run();
    put_normal();
    put_zero();
    put_inf();
    put_nan();
    put_subnormal();
    put_overflow();
  endtask
endclass
