`ifndef AXI_INTERFACE 
`define AXI_INTERFACE


interface axi_intf(input clk);

    // Width of data bus in bits
    parameter DATA_WIDTH = 32;
    // Width of address bus in bits
    parameter ADDR_WIDTH = 16;
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH = (DATA_WIDTH/8);
    // Width of ID signal
    parameter ID_WIDTH = 8;
    // Extra pipeline register on output
    parameter PIPELINE_OUTPUT = 0;

    logic reset;

    //WRITE ADDRESS BUS
    logic  [ID_WIDTH-1:0]    awid;
    logic  [ADDR_WIDTH-1:0]  awaddr;
    logic  [7:0]             awlen;
    logic  [2:0]             awsize;
    logic  [1:0]             awburst;
    logic                    awlock;
    logic  [3:0]             awcache;
    logic  [2:0]             awprot;
    logic                    awvalid;
    logic                    awready;
    
    //WRITE DATA BUS
    logic  [ID_WIDTH-1:0]    wid;
    logic  [DATA_WIDTH-1:0]  wdata;
    logic  [STRB_WIDTH-1:0]  wstrb;
    logic                    wlast;
    logic                    wvalid;
    logic                    wready;
    
    //WRITE RESPONSE BUS
    logic  [ID_WIDTH-1:0]    bid;
    logic  [1:0]             bresp;
    logic                    bvalid;
    logic                    bready;
    
    //READ ADDRESS BUS
    logic  [ID_WIDTH-1:0]    arid;
    logic  [ADDR_WIDTH-1:0]  araddr;
    logic  [7:0]             arlen;
    logic  [2:0]             arsize;
    logic  [1:0]             arburst;
    logic                    arlock;
    logic  [3:0]             arcache;
    logic  [2:0]             arprot;
    logic                    arvalid;
    logic                    arready;
    
    //READ DATA BUS
    logic  [ID_WIDTH-1:0]    rid;
    logic  [DATA_WIDTH-1:0]  rdata;
    logic  [1:0]             rresp;
    logic                    rlast;
    logic                    rvalid;
    logic                    rready;


    //WRITE ADDRESS BUS
    
    clocking cb @(posedge clk);

       output reset;
      //WRITE ADDRESS BUS
      input awready;
      output awid,awaddr,awlen,awsize,awburst,awvalid,awcache,awprot,awlock;

      //WRITE DATA BUS
      input wready;
      output wid,wdata,wstrb,wlast,wvalid;
       
      //WRITE RESPONSE BUS
      input bid,bresp,bvalid;
      output bready;

      //READ ADDRESS BUS
      input arready;
      output arid,araddr,arlen,arsize,arburst,arvalid,arcache,arprot,arlock;
       
      //READ DATA BUS
      input rid,rdata,rresp,rlast,rvalid;
      output rready;

    endclocking

//     modport tb_drv(clocking cb);

   clocking cb_mon @(posedge clk);

      //default input #9;
       
      //WRITE ADDRESS BUS
      input reset;
      input awready;
      input awid,awaddr,awlen,awsize,awburst,awvalid,awcache,awprot,awlock;

      //WRITE DATA BUS
      input wready;
      input wid,wdata,wstrb,wlast,wvalid;
       
      //WRITE RESPONSE BUS
      input bid,bresp,bvalid;
      input bready;

      //READ ADDRESS BUS
      input arready;
      input arid,araddr,arlen,arsize,arburst,arvalid,arcache,arprot,arlock;
       
      //READ DATA BUS
      input rid,rdata,rresp,rlast,rvalid;
      input rready;

    endclocking

//     modport tb_mon(clocking cb_mon);


    // Clocking Block for RESPONDER
    clocking slave_cb @(posedge clk);

    default input #0 output #1;

    //--> Write Address Channel:-
    input  awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awvalid;
    output awready;

    //--> Write Data Channel:-
    input  wid, wdata, wstrb, wlast, wvalid;
    output wready;

    //--> Write Respose Channel:-
    output  bid, bresp, bvalid;
    input bready;

    //--> Read Address Channel:-
    input  arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arvalid;
    output arready;
    
    //--> Read Data Channel:-
    output  rid, rdata, rresp, rlast, rvalid;
    input rready;

    endclocking


endinterface




`endif


