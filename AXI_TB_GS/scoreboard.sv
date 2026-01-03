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

	T ref_pkt;
	T act_pkt;
	static bit [31:0] num_matches, num_mismatches;
	bit [ DATA_WIDTH-1 : 0 ]  mem [ bit [ ADDR_WIDTH - 1 : 0 ] ];              // key - addr,value -data
	// bit [ DATA_WIDTH-1 : 0 ]  fifoQ [ bit [ ADDR_WIDTH - 1 : 0 ] ] [$];       // Only for Fixed transaction
	//               value   arr_name  [ key ]

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

		if(!ref_pkt.bresp || ref_pkt.bresp == 2'b01)  begin
			
			ref_pkt.calculate_wrap_range(ref_pkt.awaddr, ref_pkt.awlen, ref_pkt.awsize);

			foreach(ref_pkt.wdataQ[i]) begin
				write_to_mem(ref_pkt.awaddr, ref_pkt.awsize, ref_pkt.wdataQ[i],ref_pkt.wstrbQ[i]);
				
				case(ref_pkt.awburst)

					FIXED: begin
						ref_pkt.awaddr = ref_pkt.awaddr;
					end
				
					INCR: begin		
						ref_pkt.awaddr += 2**ref_pkt.awsize;
					end

					WRAP: begin
						ref_pkt.awaddr += 2**ref_pkt.awsize;
						ref_pkt.awaddr = ref_pkt.check_wrap(ref_pkt.awaddr);
					end

                endcase
			end
			

		end

		//display error had occurred  with corresponding code
		else                        
			`uvm_info( "SCB_INP", $sformatf( "BRESP: %0s", ref_pkt.bresp.name ), UVM_NONE );
		
	endfunction

	virtual function void write_out(T pkt);

		$cast( act_pkt, pkt.clone() );

		act_pkt.calculate_wrap_range(act_pkt.awaddr, act_pkt.awlen, act_pkt.awsize);

		foreach( act_pkt.rdataQ[i] ) begin
			compare( act_pkt.araddr, act_pkt.rdataQ[i], act_pkt.arsize, act_pkt.rrespQ[i] );

			case(act_pkt.arburst)

				FIXED: begin
					act_pkt.araddr = act_pkt.araddr;
				end
			
				INCR: begin		
					act_pkt.araddr += 2**act_pkt.arsize;
				end

				WRAP: begin
					act_pkt.araddr += 2**act_pkt.arsize;
					act_pkt.araddr = act_pkt.check_wrap(act_pkt.araddr);
				end

            endcase
		end            			               
		
	endfunction

	function void write_to_mem( bit [ ADDR_WIDTH : 0 ] addr, bit [2:0] burst_size, bit [ DATA_WIDTH : 0 ] data, bit [ STRB_WIDTH : 0 ] strb);
                
		`uvm_info(get_type_name(), $sformatf(" %d Writing at addr = %h, data = %h",i, tr.addr, tr.dataQ[i]), UVM_DEBUG);
		int lane;
    	int lane_offset;

		lane_offset = addr % (`DATA_BUS_WIDTH/8);
		for (int j = 0; j < (2**burst_size); j++) begin
			lane = lane_offset + j;
			if (strb[lane]) begin
				mem[addr + j] = data[lane*8 +: 8];
			end
		end
		
	endfunction


	// Comparing the values address by address
	//   function void compare ( bit [ ADDR_WIDTH - 1 : 0 ] addr, [ DATA_WIDTH - 1: 0 ] rdata, [2:0] arsize, [ 1 : 0 ] rresp );
	function void compare ( bit [ ADDR_WIDTH - 1 : 0 ] addr, [ DATA_WIDTH - 1: 0 ] data, [2:0] burst_size, [ 1 : 0 ] resp );
		
		if( !resp || resp = 2'b01)  begin

			for( bit[2:0] j = 0; j < (1 << burst_size); j++)   begin

				if( mem[addr + j] == data[ j*8 +: 8 ] ) begin
					`uvm_info("SCB_DATA_MATCH", $sformatf("For addr = %0d, write data is matching  with read data %0h ", addr+j, mem[addr+j]), UVM_MEDIUM);
					++num_matches;
				end

				else  begin 
					`uvm_error("SCB_DATA_MISMATCH",$sformatf("For addr = %0d, expected data %0h is mismatching  with recvd data %0h ", addr+j, mem[addr+j], data[j*8 +: 8  ]));
					++ num_mismatches;
				end

			end 

		end  

		else  `uvm_error("SCB_RRESP", $sformatf(" Beat with addr %0h is erroneous ", addr ) );
				
	endfunction

	virtual function void extract_phase(uvm_phase phase);
		uvm_config_db #(int)::set(null, "uvm_test_top.env", "num_matches", num_matches);
		uvm_config_db #(int)::set(null, "uvm_test_top.env", "num_mismatches", num_mismatches);
	endfunction

	function void report_phase (uvm_phase phase);
		`uvm_info("SCB",$sformatf("Scoreboard completed with matches=%0d mismatches=%0d", num_matches, num_mismatches), UVM_NONE);
	endfunction

endclass


