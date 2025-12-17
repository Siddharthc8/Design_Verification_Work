class axi_base_test extends uvm_test;
`uvm_component_utils(axi_base_test)

	environment env;
    virtual axi_intf vif;
  
`NEW_COMP

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
  env = environment::type_id::create("env", this);
  uvm_config_db #(virtual axi_intf)::set( this, "env.m_agent.drvr", "drvr_if", vif );
  uvm_config_db #(virtual axi_intf)::set( this, "env.m_agent.iMon", "iMon_if", vif );
  uvm_config_db #(virtual axi_intf)::set( this, "env.s_agent.oMon", "oMon_if", vif );
endfunction

function void end_of_elaboration_phase(uvm_phase phase);
super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
endfunction


function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    if(scoreboard::num_mismatches > 0 || scoreboard::num_matches == 0) begin
        `uvm_error("STATUS", $sformatf("TEST FAIL, num_matches = %0d, num_mismatches = %0d", scoreboard::num_matches, scoreboard::num_mismatches) );
    end  
    else begin
        `uvm_info("STATUS", $sformatf("TEST PASS, num_matches = %0d, num_mismatches = %0d", scoreboard::num_matches, scoreboard::num_mismatches), UVM_NONE );
    end
    
endfunction
endclass



/*
//  For coverage class
`uvm_info(get_type_name(), 
              "\n========================================\n COVERAGE SUMMARY\n========================================", 
              UVM_LOW)

*/