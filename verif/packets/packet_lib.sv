import vpu_pkg::*;

class NormalPacket extends Packet;
  constraint normal_data {
    foreach (src0_data[i]) {
      src0_data[i][30:23] inside {[8'h01:8'hFE]};
    }
    foreach (src1_data[i]) {
      src1_data[i][30:23] inside {[8'h01:8'hFE]};
    }
  }
endclass

class ZeroPacket extends Packet;
  constraint zero_data {
    foreach (src0_data[i]) {
      src0_data[i] inside {32'h00000000, 32'h80000000};
    }
    foreach (src1_data[i]) {
      src1_data[i] inside {32'h00000000, 32'h80000000};
    }
  }
endclass

class InfPacket extends Packet;
  constraint inf_data {
    foreach (src0_data[i]) {
      src0_data[i] inside {32'h7F800000, 32'hFF800000};
    }
    foreach (src1_data[i]) {
      src1_data[i] inside {32'h7F800000, 32'hFF800000};
    }
  }
endclass

class NanPacket extends Packet;
  constraint nan_data {
    foreach (src0_data[i]) {
      src0_data[i][30:23] == 8'hFF;
      src0_data[i][22:0] != 23'h0;
    }
    foreach (src1_data[i]) {
      src1_data[i][30:23] == 8'hFF;
      src1_data[i][22:0] != 23'h0;
    }
  }
endclass

class SubnormalPacket extends Packet;
  constraint subnormal_data {
    foreach (src0_data[i]) {
      src0_data[i][30:23] == 8'h00;
      src0_data[i][22:0] != 23'h0;
    }
    foreach (src1_data[i]) {
      src1_data[i][30:23] == 8'h00;
      src1_data[i][22:0] != 23'h0;
    }
  }
endclass

class OverflowPacket extends Packet;
  constraint overflow_data {
    op_t inside {VPU_FADD, VPU_FMUL};
    foreach (src0_data[i]) {
      src0_data[i][30:23] inside {[8'hF0:8'hFE]};
      src0_data[i][31] == 1'b0;
    }
    foreach (src1_data[i]) {
      src1_data[i][30:23] inside {[8'hF0:8'hFE]};
      src1_data[i][31] == 1'b0;
    }
  }
endclass

class MixedSpecialPacket extends Packet;
  constraint mixed_special_data {
    foreach (src0_data[i]) {
      src0_data[i] dist {
        32'h00000000 := 10,                       // +0
        32'h80000000 := 10,                       // -0
        32'h7F800000 := 10,                       // +inf
        32'hFF800000 := 10,                       // -inf
        [32'h7F800001:32'h7FFFFFFF] :/ 10,        // +NaN range
        [32'hFF800001:32'hFFFFFFFF] :/ 10,        // -NaN range
        [32'h00000001:32'h007FFFFF] :/ 10,        // positive subnormal range
        [32'h80000001:32'h807FFFFF] :/ 10,        // negative subnormal range
        [32'h00800000:32'h7F7FFFFF] :/ 20         // positive normal range
      };
    }
    foreach (src1_data[i]) {
      src1_data[i] dist {
        32'h00000000 := 10,                       // +0
        32'h80000000 := 10,                       // -0
        32'h7F800000 := 10,                       // +inf
        32'hFF800000 := 10,                       // -inf
        [32'h7F800001:32'h7FFFFFFF] :/ 10,        // +NaN range
        [32'hFF800001:32'hFFFFFFFF] :/ 10,        // -NaN range
        [32'h00000001:32'h007FFFFF] :/ 10,        // positive subnormal range
        [32'h80000001:32'h807FFFFF] :/ 10,        // negative subnormal range
        [32'h00800000:32'h7F7FFFFF] :/ 20         // positive normal range
      };
    }
  }
endclass
