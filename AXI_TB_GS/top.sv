`include "uvm_pkg.sv"
import uvm_pkg::*;

`include "common.sv"
`include "axi_intf.sv"
`include "transaction.sv"
`include "sequencer.sv"
`include "seq_lib.sv"
`include "driver.sv"
`include "imonitor.sv"
`include "axi_responder.sv"
`include "master_agent.sv"
`include "omonitor.sv"
`include "slave_agent.sv"
`include "scoreboard.sv"
`include "environment.sv"
`include "test_lib.sv"

module top;

	reg clk;

  // Interface instantiation
    axi_intf vif(clk);

    // Clock Instantiation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end



    initial begin
      run_test("axi_n_wr_rd_test");
    end


    initial begin
      uvm_config_db#(virtual axi_intf)::set(null, "*", "VIF", vif);
    //     reset_dut();
    end


    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, top);   // Replace with top module name
    end


endmodule