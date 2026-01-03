`include "uvm_pkg.sv"
import uvm_pkg::*;

`include "common.sv"
`include "axi_intf.sv"
`include "transaction.sv"
`include "seq_lib.sv"
`include "sequencer.sv"
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

// DUT instantiation
    // axi_dut dut (
    //     .clk            (clk),
    //   .rst            (vif.reset),

    //     // WRITE ADDRESS
    //     .s_axi_awid     (vif.awid),
    //     .s_axi_awaddr   (vif.awaddr),
    //     .s_axi_awlen    (vif.awlen),
    //     .s_axi_awsize   (vif.awsize),
    //     .s_axi_awburst  (vif.awburst),
    //     .s_axi_awlock   (vif.awlock),
    //     .s_axi_awcache  (vif.awcache),
    //     .s_axi_awprot   (vif.awprot),
    //     .s_axi_awvalid  (vif.awvalid),
    //     .s_axi_awready  (vif.awready),

    //     // WRITE DATA
    //     .s_axi_wid      (vif.wid),
    //     .s_axi_wdata    (vif.wdata),
    //     .s_axi_wstrb    (vif.wstrb),
    //     .s_axi_wlast    (vif.wlast),
    //     .s_axi_wvalid   (vif.wvalid),
    //     .s_axi_wready   (vif.wready),

    //     // WRITE RESPONSE
    //     .s_axi_bid      (vif.bid),
    //     .s_axi_bresp    (vif.bresp),
    //     .s_axi_bvalid   (vif.bvalid),
    //     .s_axi_bready   (vif.bready),

    //     // READ ADDRESS
    //     .s_axi_arid     (vif.arid),
    //     .s_axi_araddr   (vif.araddr),
    //     .s_axi_arlen    (vif.arlen),
    //     .s_axi_arsize   (vif.arsize),
    //     .s_axi_arburst  (vif.arburst),
    //     .s_axi_arlock   (vif.arlock),
    //     .s_axi_arcache  (vif.arcache),
    //     .s_axi_arprot   (vif.arprot),
    //     .s_axi_arvalid  (vif.arvalid),
    //     .s_axi_arready  (vif.arready),

    //     // READ DATA
    //     .s_axi_rid      (vif.rid),
    //     .s_axi_rdata    (vif.rdata),
    //     .s_axi_rresp    (vif.rresp),
    //     .s_axi_rlast    (vif.rlast),
    //     .s_axi_rvalid   (vif.rvalid),
    //     .s_axi_rready   (vif.rready)
    // );


    // Clock Instantiation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end



    initial begin
      run_test("axi_wr_rd_test");
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