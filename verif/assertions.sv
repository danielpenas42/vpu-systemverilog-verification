module vpu_assertions
  import vpu_pkg::*;
(
  input logic              clk,
  input logic              rst_n,
  input logic              wr_valid,
  input logic              wr_ready,
  input logic [VIDX_W-1:0] wr_idx,
  input logic [VEC_W-1:0]  wr_data
);

  property writeback_stable_when_stalled;
    @(posedge clk) disable iff (!rst_n)
      wr_valid && !wr_ready |=> $stable(wr_idx) && $stable(wr_data);
  endproperty

  assert property (writeback_stable_when_stalled)
    else $error("writeback changed while stalled");

  property valid_drop_only_after_hdsk;
    @(posedge clk) disable iff (!rst_n)
      wr_valid && !wr_ready |=> wr_valid;
  endproperty

  assert property (valid_drop_only_after_hdsk)
    else $error("wr_valid dropped before writeback handshake");

  property writeback_not_unknown_when_valid;
    @(posedge clk) disable iff (!rst_n)
      wr_valid |-> !$isunknown(wr_idx) && !$isunknown(wr_data);
  endproperty

  assert property (writeback_not_unknown_when_valid)
    else $error("writeback has X/Z while wr_valid is high");

  property reset_clears_writeback;
    @(posedge clk)
      !rst_n |-> !wr_valid;
  endproperty

  assert property (reset_clears_writeback)
    else $error("wr_valid should be low during reset");

endmodule
