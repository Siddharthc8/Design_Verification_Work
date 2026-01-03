`ifndef AXI_TRANSACTION
`define AXI_TRANSACTION

typedef enum { UNKNOWN, RESET, STIMULUS } pkt_kind;
typedef enum { WRITE, READ } oper_type;
typedef enum { FIXED, INCR, WRAP, RSVD } burst_type;
typedef enum { OKAY, EXOKAY, SLVERR, DECERR } resp_type;

class transaction extends uvm_sequence_item;
   
    bit reset;
    pkt_kind kind;
    oper_type oper;


    //WRITE ADDRESS BUS
    rand bit  [ID_WIDTH-1:0]        awid;          // [3:0] in AXI 3 and [7:0] in AXI 4
    rand bit  [ADDR_WIDTH-1:0]      awaddr;    
    rand bit  [3:0]        awlen;
    rand bit  [2:0]        awsize;
    rand burst_type    awburst;
    bit               awvalid;
    bit                    awready;

    bit                    awlock;
    bit  [3:0]             awcache;
    bit  [2:0]             awprot;
  

    
    //WRITE DATA BUS
    rand bit  [ID_WIDTH-1:0]        wid;  
    rand bit  [DATA_WIDTH-1:0]       wdata;
    rand  bit  [STRB_WIDTH-1:0]        wstrb;
    bit                wlast;
    bit               wvalid;
    bit                wready;
 
    
    //WRITE RESPONSE BUS
    rand bit  [ID_WIDTH:0]             bid;
    resp_type           bresp;
    bit                    bvalid;
    bit               bready;
    
    //READ ADDRESS BUS
    rand bit  [ID_WIDTH-1:0]        arid;
    rand bit  [ADDR_WIDTH-1:0]       araddr;
    rand bit  [7:0]        arlen;
    rand bit  [2:0]        arsize;
    rand burst_type      arburst;
    bit               arvalid;
    bit                    arready;

    bit                    arlock;
    bit  [3:0]             arcache;
    bit  [2:0]             arprot;
   
    
    //READ DATA BUS
    rand  bit  [ID_WIDTH-1:0]             rid;
    bit  [DATA_WIDTH-1:0]            rdata;
    resp_type            rresp;
    bit                    rlast;
    bit                    rvalid;
    bit               rready;

    //QUEUE DECLARATIONS
    bit [DATA_WIDTH-1:0] wdataQ[$];
    bit [DATA_WIDTH-1:0] wstrbQ[$]; 
    bit [DATA_WIDTH-1:0] rdataQ[$];
  	bit         [1:0]  rrespQ[$];
  
    // Transaction local signals
    bit [`ADDR_BUS_WIDTH-1:0] wrap_lower_addr;
    bit [`ADDR_BUS_WIDTH-1:0] wrap_upper_addr;
  
  // CONSTRAINTS
  
    constraint id_cw{ awid == wid; wid == bid; solve awid before wid;}
    constraint id_cr{//id  inside {[1:15]};
      arid == rid;}

    constraint size_c{ soft awsize==2 && arsize==2;}
    constraint burst_c{soft awburst==INCR;}               
    constraint len_c{soft awlen==arlen;}                       // —--> TEMP
    constraint addr_c{
                        soft awaddr inside {[100:200]};
                        soft araddr inside {[100:200]};
        }
    constraint unaligned_addr{awaddr% 2**(awsize)!=0;}
    constraint aligned_addr{awaddr%(1<< awsize)==0;}     // Note “1<<size” equivalent to “2^size”

    // constraint strobe_c { solve awsize before wstrb; 
                        // soft wstrb inside { [ 0: ( 1 << ( 1 << awsize ) -1) ] };
    // $countones(wstrb) <= 1<< awsize; 
    // }

    constraint addr_valid {
				awaddr %(1<< awsize)==0;
}

constraint wstrb_starting_lane { 
  							wstrb == calc_start_lane( awaddr, awsize, BUS_LENGTH/8 );
             }

function bit [ BUS_LENGTH/8 -1 : 0 ] calc_start_lane( bit [ADDR_WIDTH:0] awaddr, bit[2:0] awsize, int bus_length);

// 	int strb_width = bus_length;
    bit [ STRB_WIDTH -1 : 0 ] strb;
    int off_set;
    int num_ones;

	if(  (1 << awsize)  != STRB_WIDTH) begin                // awsize=2,bus_length=8,awaddr=4
        off_set = awaddr % bus_length;                 //4
        repeat(1 << awsize) begin
            strb[ off_set++ ] = 1;
        end
    end
  
    else begin
      num_ones = $urandom_range( 1 , STRB_WIDTH );                     //no of 1s ->2   ,0011,0110,1100
      off_set = $urandom_range( 0 , STRB_WIDTH - num_ones );
      repeat(num_ones)
        strb[off_set++] = 1;

    end

	return strb;

endfunction


function void calculate_wrap_range(input bit [ADDR_BUS_WIDTH-1:0] addr, bit [3:0] len, bit [3:0] size );

    bit [31:0] tx_size;
    bit [31:0] offset;

    tx_size = (len + 1) * (2**size);
    offset = (addr % tx_size);

    wrap_lower_addr = addr - offset;
    wrap_upper_addr = wrap_lower_addr + tx_size - 1;

    `uvm_info("AXI_TX WRAP CALC", $sformatf(" addr = %h", addr), UVM_MEDIUM);
    `uvm_info("AXI_TX WRAP CALC", $sformatf(" wrap_lower_addr = %h ", wrap_lower_addr), UVM_MEDIUM);
    `uvm_info("AXI_TX WRAP CALC", $sformatf(" wrap_upper_addr = %h ", wrap_upper_addr), UVM_MEDIUM);

endfunction

function void check_wrap(input [ADDR_WIDTH-1:0] addr);
    if(addr >= wrap_upper_addr) begin
        addr = wrap_lower_addr;
    end
endfunction
  


  `uvm_object_utils_begin(transaction)
   
   `uvm_field_int(reset,UVM_ALL_ON)
   
   //WRITE ADDRESS BUS
   `uvm_field_int(awid,UVM_ALL_ON)
   `uvm_field_int(awaddr,UVM_ALL_ON)
   `uvm_field_int(awlen,UVM_ALL_ON)
   `uvm_field_int(awsize,UVM_ALL_ON)
   `uvm_field_int(awburst,UVM_ALL_ON)
   `uvm_field_int(awlock,UVM_ALL_ON)
   `uvm_field_int(awcache,UVM_ALL_ON)
   `uvm_field_int(awprot,UVM_ALL_ON)
   `uvm_field_int(awvalid,UVM_ALL_ON)
   `uvm_field_int(awready,UVM_ALL_ON)
   `uvm_field_queue_int(awaddrQ,UVM_ALL_ON)

   //WRITE DATA BUS
   `uvm_field_int(wid,UVM_ALL_ON)
   `uvm_field_int(wdata,UVM_ALL_ON)
   `uvm_field_int(wstrb,UVM_ALL_ON)
   `uvm_field_int(wlast,UVM_ALL_ON)
   `uvm_field_int(wvalid,UVM_ALL_ON)
   `uvm_field_int(wready,UVM_ALL_ON)
   `uvm_field_queue_int(wdataQ,UVM_ALL_ON)
   `uvm_field_queue_int(wstrbQ,UVM_ALL_ON)

   //WRITE RESPONSE BUS
   `uvm_field_int(bid,UVM_ALL_ON)
   `uvm_field_int(bresp,UVM_ALL_ON)
   `uvm_field_int(bvalid,UVM_ALL_ON)
   `uvm_field_int(bready,UVM_ALL_ON)

   //READ ADDRESS BUS
   `uvm_field_int(arid,UVM_ALL_ON)
   `uvm_field_int(araddr,UVM_ALL_ON)
   `uvm_field_int(arlen,UVM_ALL_ON)
   `uvm_field_int(arsize,UVM_ALL_ON)
   `uvm_field_int(arburst,UVM_ALL_ON)
   `uvm_field_int(arlock,UVM_ALL_ON)
   `uvm_field_int(arcache,UVM_ALL_ON)
   `uvm_field_int(arprot,UVM_ALL_ON)
   `uvm_field_int(arvalid,UVM_ALL_ON)
   `uvm_field_int(arready,UVM_ALL_ON)
   `uvm_field_queue_int(araddrQ,UVM_ALL_ON)

   //READ DATA BUS
   `uvm_field_int(rid,UVM_ALL_ON)
  `uvm_field_int(rdata,UVM_ALL_ON)
   `uvm_field_int(rresp,UVM_ALL_ON)
   `uvm_field_int(rlast,UVM_ALL_ON)
   `uvm_field_int(rvalid,UVM_ALL_ON)
   `uvm_field_int(rready,UVM_ALL_ON)
  `uvm_field_queue_int(rdataQ,UVM_ALL_ON)
  `uvm_field_queue_int(rrespQ,UVM_ALL_ON)
   
   `uvm_object_utils_end

   function new(string name="transaction");
      super.new(name);
   endfunction

endclass



`endif


























/*
—-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

APB/AHB:bit [7:0] [127:0] mem; PADDR =32 bits=4 bytes 
Aligned address(32%4==0): 0,4,8,12…
  
AXI : bit [7:0] [127:0] mem; 
Aligned address: 0,4,8,12… + between the two, depending upon awsize 
// STRB EXPlanation


bus data length = 32 bits/4 bytes
wstrb = 4’0000
awsize  = 1 / 2 bytes

1)    Question 1 addr  = 4
1st check for addr mod 2**awsize == 0 
awaddr = 8’b00000100 % 2 == 0

2nd check for addr mod bus_length remainder => starting lane for strb
awaddr = 8’b00000100 % bus length  2%4  = 2
—----------------------------------------------------------------------
2)    Question 1 addr  = 8
1st check for addr mod 2**awsize == 0 
awaddr = 8’b00001000 % 2 == 0

2nd check for addr mod bus_length remainder => starting lane  for strb
awaddr = 8’b00001000 % bus length  8%4 = 0  
wstrb = 0011
—----------------------------------------------------------------------
3)    Question 1 addr  = 6
1st check for addr mod 2**awsize == 0 
awaddr = 8’b00000110 % 2 == 0

2nd check for addr mod bus_length remainder => starting lane for strobe
awaddr = 8’b00000110 % bus length  6%4 = 2
I’m sending 2 bytes,starting lane 2 => 1100

—----------------------------------------------------------------------
4)    Question 4 addr  = 9,awsize =2 => 4 bytes
1st check for addr mod 2**awsize == 0 
awaddr = 8’b00001001 % 2 =1  !=0 => This transaction is a violation

—----------------------------------------------------------------------
5)    Question 5 addr  = 2 ,awsize =0
1st check for addr mod 2**awsize == 0 
awaddr = 8’b00000010 % 1 == 0

2nd check for addr mod bus_length remainder => starting lane for strobe
awaddr = 8’b00000010 % bus length  2%4 = 2
I’m sending 1 byte,starting lane 2 => 0100

—----------------------------------------------------------------------
6)    Question 6 addr  = 9 ,awsize =0
1st check for addr mod 2**awsize == 0 
awaddr = 8’b00001001 % 1 == 0

2nd check for addr mod bus_length remainder => starting lane for strobe
awaddr = 8’b00001001 % bus length  9%4 = 1
I’m sending 1 byte,starting lane 1 => 0010

—----------------------------------------------------------------------
7)    Question 7 addr  = 8 ,awsize = 2 => 4 bytes
1st check for addr mod 2**awsize == 0 
awaddr = 8’b00001000 % 4 == 0

2nd check for addr mod bus_length remainder => starting lane for strobe
awaddr = 8’b00001000 % bus length  8%4 = 0
I’m sending 4 bytes,starting lane 0 => 1111

—----------------------------------------------------------------------
8)    Question 8 addr  = 4 ,awsize = 2 => 4 bytes,bus :64 bits =>8 bytes
1st check for addr mod 2**awsize == 0 
awaddr = 8’b00000100 % 4 == 0

2nd check for addr mod bus_length remainder => starting lane for strobe
awaddr = 8’b00000100 % bus length  4%8 = 4
I’m sending 4 bytes,starting lane 4 => 1111_0000

constraint addr_valid {
				awaddr %(1<< awsize)==0;
}
constraint wstrb_starting_lane { 
					wstrb=calc_start_lane(awaddr,awsize,BUS_LENGTH/8)
             }
function bit [$bits(wstrb)-1:0] calc_start_lane( bit [ADDR_WIDTH:0] awaddr, bit[2:0] awsize, int bus_length);
	bit [$bits(wstrb)-1:0] strb;
	int strb_width = bus_length;
	if(  (1<<awsize)  != bus_length) begin// awsize=2,bus_length=8,awaddr=4
int temp = 0; 
off_set= awaddr% bus_length;  //4
	repeat(1<<awsize) begin
		strb[off_set++] = 1;
end
end
else strb = $urandom();
return strb;
endfunction
p=$urandom_range(1,4);//no of 1s ->2   ,0011,0110,1100
q=$urandom_range(0,3 );
repeat(p)
       strb[q++];


num_ones = $urandom_range( 1 , strb_width );//no of 1s ->2   ,0011,0110,1100
off_set = $urandom_range( 0 , strb_width - num_ones );
repeat(num_ones)
       strb[off_set++];



num_ones          off_set
      1                     0,1,2,3
      2                     0,1,2
      3                     0,1
      4                     0


*/



