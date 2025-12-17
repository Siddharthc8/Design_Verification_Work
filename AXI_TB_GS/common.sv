`ifndef AXI_COMMON
`define AXI_COMMON

parameter WVALID_TIMEOUT = 32;
parameter WREADY_TIMEOUT = 32; 

parameter RVALID_TIMEOUT = 32;
parameter RREADY_TIMEOUT  = 32;

parameter DATA_WIDTH = 32;                  // 4 bytes
parameter ADDR_WIDTH = 16;
parameter BUS_LENGTH = 32;

parameter STRB_WIDTH = (DATA_WIDTH/8);
parameter ID_WIDTH = 8;
parameter BLOCK_SIZE = 32;


`define NEW_COMP \
function new(string name = "", uvm_component parent); \
    super.new(name, parent); \
endfunction


`define NEW_OBJ \
function new(string name = ""); \
    super.new(name); \
endfunction


`endif


