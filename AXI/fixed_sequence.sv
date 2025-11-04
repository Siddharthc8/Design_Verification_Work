class fixed_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(fixed_sequence)

  function new(string name = "fixed_sequnence");
    super.new(name);
    set_automatic_phase_objection(1);
  endfunction


virtual task body();
REQ rand_pkt;
rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
repeat(2) begin
        `uvm_create(req);
       rand_pkt.unaligned_addr.constraint_mode(0);
       rand_pkt.aligned_addr.constraint_mode(1);
        rand_pkt.randomize() with {awburst==0;awsize==3'b010;awlen==0;wstrb==4'b1111;};
        req.copy(rand_pkt);
        req.kind=STIMULUS;
        start_item(req);
        finish_item(req);
        `uvm_info(" SEQ",$sformatf("FIXED len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.awlen+1,req.awaddr),UVM_MEDIUM);
    end
    endtask

endclass
