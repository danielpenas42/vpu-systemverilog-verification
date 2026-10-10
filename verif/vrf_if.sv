interface vrf_if (input logic clk);
    import vpu_pkg::*;

    logic      load0_en;
    vreg_idx_t load0_idx;
    vec_t      load0_data;
    logic      load1_en;
    vreg_idx_t load1_idx;
    vec_t      load1_data;

    clocking cb @(posedge clk);
        inout load0_en;
        inout load0_idx;
        inout load0_data;
        inout load1_en;
        inout load1_idx;
        inout load1_data;
    endclocking
endinterface
