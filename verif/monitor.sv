import vpu_pkg::*;

class Monitor;
  virtual vpu_if vpu_vif;
  mailbox #(Result) mon2scb;

  function new(virtual vpu_if vpu_vif,
               mailbox #(Result) mon2scb);
    this.vpu_vif = vpu_vif;
    this.mon2scb = mon2scb;
  endfunction

  task run();
    Result r;

    forever begin
      @(vpu_vif.cb);

      if (vpu_vif.cb.wr_valid && vpu_vif.cb.wr_ready) begin
        r = new();
        r.vd   = vpu_vif.cb.wr_idx;
        r.data = vpu_vif.cb.wr_data;

        r.display("MON");
        mon2scb.put(r);
      end
    end
  endtask
endclass
