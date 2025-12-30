//  SCOREBOARD

class scoreboard #(type T=transaction) extends uvm_scoreboard;

typedef scoreboard #(T) scb_type;

`uvm_component_param_utils(scb_type)

const static string type_name= $sformatf("scoreboard #(%0s)",$typename(T));

virtual function string get_type_name();
return type_name;
endfunction

`uvm_analysis_imp_decl(_in)
`uvm_analysis_imp_decl(_out)

uvm_analysis_imp_in #(T,scb_type) mon_in;
uvm_analysis_imp_out #(T,scb_type) mon_out;

//T q_inp[$]; might need in future

static bit [31:0] num_matches, num_mismatches;
	T ref_pkt;
	T in_q;
bit [ DATA_WIDTH-1 : 0 ]  mem [ bit [ ADDR_WIDTH - 1 : 0 ] ];              // key - addr,value -data

function new(string name="scoreboard",uvm_component parent);
	super.new(name,parent);
	`uvm_info(get_type_name(),"NEW scoreboard",UVM_NONE);
endfunction

virtual function void build_phase(uvm_phase phase);
	super.build_phase(phase);

	mon_in = new("mon_in", this);
	mon_out = new("mon_out", this);
endfunction
	

virtual function void write_in(T pkt);
  
	    $cast( ref_pkt, pkt.clone() );
        //	`uvm_info("SCB_INP",$sformatf("ADDR: %0p,Expected::%0p",pkt.awaddr_arr,pkt.wdata_arr),UVM_NONE);
  
		if(!ref_pkt.bresp)  begin
          
          foreach(ref_pkt.awaddr_q[i])
			write_to_mem(ref_pkt.awaddr_q[i],ref_pkt.wstrb_q[i],ref_pkt.wdata_q[i]);
          
		end
  
        //display error had occurred  with corresponding code
		else                        
			`uvm_info( "SCB_INP", $sformatf( "BRESP: %0s", ref_pkt.bresp.name ), UVM_NONE );
	
endfunction

function void write_to_mem( bit [ ADDR_WIDTH : 0 ] addr, [ DATA_WIDTH : 0 ] wdata, bit [ STRB_WIDTH : 0 ] wstrb);
	
	// if(wstrb[0]) begin
		// mem[addr] = wdata[7:0];
	// if(wstrb[1]) begin
		// mem[addr+1] = wdata[15:8];
	// if(wstrb[2]) begin
		// mem[addr+2] = wdata[23:16];
// if(wstrb[3]) begin
		// mem[addr+3] = wdata[31:24];
	

	foreach(wstrb[i])
      if(wstrb[i]) mem[addr++]=  wdata[i*8 +: 8]; //wdata[(i*8 + 8 - 1) : (i*8)]

endfunction


// Comparing the values address by address
//   function void compare ( bit [ ADDR_WIDTH - 1 : 0 ] addr, [ DATA_WIDTH - 1: 0 ] rdata, [2:0] arsize, [ 1 : 0 ] rresp );
	function void compare ( bit [ ADDR_WIDTH - 1 : 0 ] addr, [ DATA_WIDTH - 1: 0 ] rdata, [2:0] arsize, [ 1 : 0 ] rresp );
      
        if( !rresp )  begin

          for( bit[2:0] j = 0; j < (1 << arsize) ; j++)   begin

            if( mem[addr + j] == rdata[ j*8 +: 8 ] ) begin
    		 		`uvm_info("SCB_DATA_MATCH", $sformatf("For addr = %0d, write data is matching  with read data %0h ", addr+j, mem[addr+j]), UVM_MEDIUM);
                     ++num_matches;
    		  end

    		  else  begin 
      			`uvm_error("SCB_DATA_MISMATCH",$sformatf("For addr = %0d, expected data %0h is mismatching  with recvd data %0h ",addr+j, mem[addr+j], rdata[j*8 +: 8  ]));
       			 ++ num_mismatches;
    		  end
    	   end 
        end  

      else  `uvm_error("SCB_RRESP", $sformatf(" Beat with addr %0h is erroneous ", addr ) );
            
endfunction


virtual function void write_out(T recvd_pkt);

foreach( recvd_pkt.araddr_q[i] ) begin
  compare( recvd_pkt.araddr_q[i], recvd_pkt.rdata_q[i], recvd_pkt.arsize[i], recvd_pkt.rresp_q[i] );
end            			               
	
	endfunction

	virtual function void extract_phase(uvm_phase phase);
      uvm_config_db #(int)::set(null,"uvm_test_top.env","num_matches",num_matches);
      uvm_config_db #(int)::set(null,"uvm_test_top.env","num_mismatches",num_mismatches);
	endfunction

	function void report_phase (uvm_phase phase);
		`uvm_info("SCB",$sformatf("Scoreboard completed with matches=%0d mismatches=%0d",num_matches,num_mismatches),UVM_NONE);
	endfunction
endclass


