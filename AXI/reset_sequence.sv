class reset_sequence extends uvm_sequence #(transaction);

`uvm_object_utils(reset_sequence)

function new(string name="reset_sequence");
	super.new(name);
    set_automatic_phase_objection(1);
endfunction

task body();
`uvm_create(req);
req.kind=RESET;
start_item(req);
finish_item(req);
`uvm_info("RST_SEQ","reset Transaction Done",UVM_MEDIUM);
endtask
  
endclass
