class environment extends uvm_env;
	`uvm_component_utils(environment)
	bit [31:0] m_matches,m_mismatches;
	
	master_agent m_agent;
	slave_agent s_agent;
	out_of_order_scoreboard #(transaction) scb;
	
	function new(string name="environment",uvm_component parent);
		super.new(name,parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		m_agent=master_agent::type_id::create("m_agent",this);
	   s_agent=slave_agent::type_id::create("s_agent",this);
	  scb=out_of_order_scoreboard #(transaction)::type_id::create("scb",this);
	endfunction
	
    virtual function void connect_phase(uvm_phase phase);
		m_agent.ap.connect(scb.mon_in);
		s_agent.ap.connect(scb.mon_out);
	endfunction
	
	virtual function void extract_phase (uvm_phase phase);
		void'(uvm_config_db #(int)::get(this,"","matches",m_matches));
		void'(uvm_config_db #(int) ::get(this,"","mis_matches",m_mismatches));
	endfunction
	
	virtual function void report_phase(uvm_phase phase);
	
      if (m_mismatches !=0) begin
		`uvm_info("FAIL","Test failed due to mismatched packets in SCB",UVM_NONE)
		`uvm_info("FAIL",$sformatf("matched pkt_count=%0d,mismatched pkt_count =%0d",m_matches,m_mismatches),UVM_NONE)
		end
		
		else begin
		`uvm_info("PASS",$sformatf("matched pkt_count=%0d,mismatched pkt_count =%0d",m_matches,m_mismatches),UVM_NONE)
		end
	endfunction
  
endclass
	
	
