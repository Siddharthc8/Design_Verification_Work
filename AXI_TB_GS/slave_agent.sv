class slave_agent extends uvm_agent;
  `uvm_component_utils(slave_agent)
	
	oMonitor oMon;
	axi_responder responder;
    uvm_analysis_port #(transaction) ap;
	function new(string name="slave_agent",uvm_component parent);
	super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
	super.build_phase(phase);
		ap=new("ap",this);
		responder = axi_responder::type_id::create("responder", this);
	    oMon=oMonitor::type_id::create("oMon",this);
	endfunction
	
	function void connect_phase(uvm_phase phase);
	super.connect_phase(phase);
	 	oMon.analysis_port.connect(this.ap);
	endfunction
	
endclass
		 


