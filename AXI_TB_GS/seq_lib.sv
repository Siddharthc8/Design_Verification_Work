//    SEQUENCES     //
//____________________________________________

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


// ------------------------------- FIXED —--------------------------

class aligned_write_fixed_sequence extends uvm_sequence #(transaction);
// typedef transaction REQ; typedef transaction RSP;
//transaction req;

    `uvm_object_utils(aligned_write_fixed_sequence) 

    int item_count;
      function new(string name = "aligned_write_fixed_sequence");
        super.new(name);
        set_automatic_phase_objection(1);
      endfunction

    virtual task pre_body();
      if(!uvm_config_db#(int)::get(get_sequencer(), "", "WRITE_COUNT",item_count));
    endtask

    virtual task body();
    REQ rand_pkt;
    rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
    //function T create (string name = "", uvm_component parent = null, string contxt = "");

    repeat(item_count) begin
            `uvm_create(req);
           rand_pkt.unaligned_addr.constraint_mode(0);
           rand_pkt.aligned_addr.constraint_mode(1);
            rand_pkt.randomize() with {awburst==FIXED;};
            req.copy(rand_pkt);
            req.kind=STIMULUS;
            start_item(req);
            finish_item(req);
            `uvm_info(" SEQ",$sformatf("FIXED len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.awlen+1,req.awaddr),UVM_MEDIUM);
        end
        endtask

endclass

class unaligned_write_fixed_sequence extends uvm_sequence #(transaction);
// typedef transaction REQ; typedef transaction RSP;
//transaction req;

    `uvm_object_utils(unaligned_write_fixed_sequence) 

    int item_count;
      function new(string name = "unaligned_write_fixed_sequence");
        super.new(name);
        set_automatic_phase_objection(1);
      endfunction

    virtual task pre_body();
      if(!uvm_config_db#(int)::get(get_sequencer(), "", "WRITE_COUNT",item_count)); 
    endtask

    virtual task body();
        REQ rand_pkt;
        rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
        //function T create (string name = "", uvm_component parent = null, string contxt = "");

        repeat(item_count) begin
                `uvm_create(req);
               rand_pkt.unaligned_addr.constraint_mode(1);
               rand_pkt.aligned_addr.constraint_mode(0);
                rand_pkt.randomize() with {awburst==FIXED;};
                req.copy(rand_pkt);
                req.kind=STIMULUS;
                start_item(req);
                finish_item(req);
                `uvm_info(" SEQ",$sformatf("FIXED len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.awlen+1,req.awaddr),UVM_MEDIUM);
            end
        endtask

endclass


class aligned_read_fixed_sequence extends uvm_sequence #(transaction);
// typedef transaction REQ; typedef transaction RSP;
//transaction req;

    `uvm_object_utils(aligned_read_fixed_sequence) 

    int item_count;
      function new(string name = "aligned_read_fixed_sequence");
        super.new(name);
        set_automatic_phase_objection(1);
      endfunction

    virtual task pre_body();
      if(!uvm_config_db#(int)::get(get_sequencer(), "", "READ_COUNT",item_count)); 
    endtask

    virtual task body();
      REQ rand_pkt;
      rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
      //function T create (string name = "", uvm_component parent = null, string contxt = "");

      repeat(item_count) begin
              `uvm_create(req);
             rand_pkt.unaligned_addr.constraint_mode(0);
             rand_pkt.aligned_addr.constraint_mode(1);
              rand_pkt.randomize() with {arburst==FIXED;};
              req.copy(rand_pkt);
              req.kind=STIMULUS;
              start_item(req);
              finish_item(req);
              `uvm_info(" SEQ",$sformatf("FIXED len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.arlen+1,req.araddr),UVM_MEDIUM);
          end
     endtask

endclass

class unaligned_read_fixed_sequence extends uvm_sequence #(transaction);
// typedef transaction REQ; typedef transaction RSP;
//transaction req;

    `uvm_object_utils(unaligned_read_fixed_sequence) 

    int item_count;
  
      function new(string name = "unaligned_read_fixed_sequence");
        super.new(name);
        set_automatic_phase_objection(1);
      endfunction

    virtual task pre_body();
      if(!uvm_config_db#(int)::get(get_sequencer(), "", "READ_COUNT",item_count));
    endtask

    virtual task body();
        REQ rand_pkt;
        rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
        //function T create (string name = "", uvm_component parent = null, string contxt = "");

        repeat(item_count) begin
                `uvm_create(req);
               rand_pkt.unaligned_addr.constraint_mode(1);
               rand_pkt.aligned_addr.constraint_mode(0);
                rand_pkt.randomize() with {arburst==FIXED;};
                req.copy(rand_pkt);
                req.kind=STIMULUS;
                start_item(req);
                finish_item(req);
                `uvm_info(" SEQ",$sformatf("FIXED len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.arlen+1,req.araddr),UVM_MEDIUM);
            end
     endtask

endclass


// -------------------------------INCREMENT-------------------------------

class aligned_write_incr_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(aligned_write_incr_sequence)

  function new(string name = "aligned_write_incr_sequence");
    super.new(name);
    set_automatic_phase_objection(1);
  endfunction


  virtual task body();
       bit [31:0] count;
      REQ rand_pkt;
      rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());

              `uvm_create(req);
              rand_pkt.unaligned_addr.constraint_mode(0);
              rand_pkt.aligned_addr.constraint_mode(1);
              rand_pkt.randomize() with {awburst==INCR;};
              req.copy(rand_pkt);
              req.kind=STIMULUS;
              start_item(req);
              finish_item(req);
              `uvm_info("INCR WRITE",$sformatf("INCR len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.awlen+1,req.awaddr),UVM_MEDIUM);
   endtask

endclass

class unaligned_write_incr_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(unaligned_write_incr_sequence)

  function new(string name = "unaligned_write_incr_sequence");
    super.new(name);
    set_automatic_phase_objection(1);
  endfunction


    virtual task body();
         bit [31:0] count;
        REQ rand_pkt;
        rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());

        `uvm_create(req);
        rand_pkt.unaligned_addr.constraint_mode(1);
        rand_pkt.aligned_addr.constraint_mode(0);
        rand_pkt.randomize() with {awburst==INCR;};
        req.copy(rand_pkt);
        req.kind=STIMULUS;
        start_item(req);
        finish_item(req);
        `uvm_info("INCR WRITE",$sformatf("INCR len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.awlen+1,req.awaddr),UVM_MEDIUM);
    endtask

endclass


class aligned_read_incr_sequence extends uvm_sequence #(transaction);
// typedef transaction REQ; typedef transaction RSP;
//transaction req;

    `uvm_object_utils(aligned_read_incr_sequence) 

    int item_count;
  
      function new(string name = "aligned_read_incr_sequence");
        super.new(name);
        set_automatic_phase_objection(1);
      endfunction

    virtual task pre_body();
      if(!uvm_config_db#(int)::get(get_sequencer(), "", "READ_COUNT",item_count)); 
    endtask

    virtual task body();
        REQ rand_pkt;
        rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
        //function T create (string name = "", uvm_component parent = null, string contxt = "");

    	repeat(item_count) begin
            `uvm_create(req);
           rand_pkt.unaligned_addr.constraint_mode(0);
           rand_pkt.aligned_addr.constraint_mode(1);
            rand_pkt.randomize() with {arburst==INCR;};
            req.copy(rand_pkt);
            req.kind=STIMULUS;
            start_item(req);
            finish_item(req);
            `uvm_info(" SEQ",$sformatf("INCR len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.arlen+1,req.araddr),UVM_MEDIUM);
        end
    endtask

endclass

class unaligned_read_incr_sequence extends uvm_sequence #(transaction);
// typedef transaction REQ; typedef transaction RSP;
//transaction req;

    `uvm_object_utils(unaligned_read_incr_sequence) 

	int item_count;
  
  function new(string name = "unaligned_read_incr_sequence");
    super.new(name);
    set_automatic_phase_objection(1);
  endfunction

  virtual task pre_body();
    if(!uvm_config_db#(int)::get(get_sequencer(), "", "READ_COUNT",item_count)); 
  endtask

  virtual task body();
      REQ rand_pkt;
      rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
      //function T create (string name = "", uvm_component parent = null, string contxt = "");

      repeat(item_count) begin
              `uvm_create(req);
             rand_pkt.unaligned_addr.constraint_mode(0);
             rand_pkt.aligned_addr.constraint_mode(1);
              rand_pkt.randomize() with {arburst==INCR;};
              req.copy(rand_pkt);
              req.kind=STIMULUS;
              start_item(req);
              finish_item(req);
              `uvm_info(" SEQ",$sformatf("INCR len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.arlen+1,req.araddr),UVM_MEDIUM);
          end
    endtask

endclass


// ------------------------------- WRAP -------------------------------


class aligned_write_wrap_sequence extends uvm_sequence #(transaction);
  `uvm_object_utils(aligned_write_wrap_sequence)

  function new(string name = "aligned_write_wrap_sequence");
    super.new(name);
    set_automatic_phase_objection(1);
  endfunction


    virtual task body();
         bit [31:0] count;
        REQ rand_pkt;
        rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());

        `uvm_create(req);
        rand_pkt.unaligned_addr.constraint_mode(1);
        rand_pkt.aligned_addr.constraint_mode(0);
        rand_pkt.randomize() with {awburst==WRAP;};
        req.copy(rand_pkt);
        req.kind=STIMULUS;
        start_item(req);
        finish_item(req);
        `uvm_info("WRAP WRITE",$sformatf("WRAP len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.awlen+1,req.awaddr),UVM_MEDIUM);
    endtask

endclass


class unaligned_write_wrap_sequence extends uvm_sequence #(transaction);//err sequence
    `uvm_object_utils(unaligned_write_wrap_sequence)

  function new(string name = "unaligned_write_wrap_sequence");
    super.new(name);
    set_automatic_phase_objection(1);
  endfunction


    virtual task body();
         bit [31:0] count;
        REQ rand_pkt;
        rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());

        `uvm_create(req);
        rand_pkt.unaligned_addr.constraint_mode(1);
        rand_pkt.aligned_addr.constraint_mode(0);
        rand_pkt.randomize() with {awburst==WRAP;};
        req.copy(rand_pkt);
        req.kind=STIMULUS;
        start_item(req);
        finish_item(req);
        `uvm_info("WRAP WRITE",$sformatf("WRAP len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.awlen+1,req.awaddr),UVM_MEDIUM);
      endtask

endclass


class aligned_read_wrap_sequence extends uvm_sequence #(transaction);
// typedef transaction REQ; typedef transaction RSP;
//transaction req;

    `uvm_object_utils(aligned_read_wrap_sequence) 

	int item_count;
  
  function new(string name = "aligned_read_wrap_sequence");
    super.new(name);
    set_automatic_phase_objection(1);
  endfunction

    virtual task pre_body();
      if(!uvm_config_db#(int)::get(get_sequencer(), "", "READ_COUNT",item_count)); 
    endtask

    virtual task body();
        REQ rand_pkt;
        rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
        //function T create (string name = "", uvm_component parent = null, string contxt = "");

    	repeat(item_count) begin
            `uvm_create(req);
           rand_pkt.unaligned_addr.constraint_mode(0);
           rand_pkt.aligned_addr.constraint_mode(1);
            rand_pkt.randomize() with {arburst==WRAP;};
            req.copy(rand_pkt);
            req.kind=STIMULUS;
            start_item(req);
            finish_item(req);
            `uvm_info("WRAP SEQ",$sformatf("WRAP len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.arlen+1,req.araddr),UVM_MEDIUM);
        end
    endtask

endclass


class unaligned_read_wrap_sequence extends uvm_sequence #(transaction);
// typedef transaction REQ; typedef transaction RSP;
//transaction req;

    `uvm_object_utils( unaligned_read_wrap_sequence) 

    int item_count;
  
      function new(string name = " unaligned_read_wrap_sequence");
        super.new(name);
        set_automatic_phase_objection(1);
      endfunction

    virtual task pre_body();
      if(!uvm_config_db#(int)::get(get_sequencer(), "", "READ_COUNT",item_count));
    endtask

    virtual task body();
        REQ rand_pkt;
        rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
        //function T create (string name = "", uvm_component parent = null, string contxt = "");

    	repeat(item_count) begin
            `uvm_create(req);
           rand_pkt.unaligned_addr.constraint_mode(0);
           rand_pkt.aligned_addr.constraint_mode(1);
            rand_pkt.randomize() with {arburst==WRAP;};
            req.copy(rand_pkt);
            req.kind=STIMULUS;
            start_item(req);
            finish_item(req);
            `uvm_info(" SEQ",$sformatf("WRAP len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.arlen+1,req.araddr),UVM_MEDIUM);
        end
    endtask

endclass



// ERROR WRAP SEQUENCE

class error_aligned_write_wrap_sequence extends uvm_sequence #(transaction);
  `uvm_object_utils(aligned_write_wrap_sequence)

  function new(string name = "aligned_write_wrap_sequence");
    super.new(name);
    set_automatic_phase_objection(1);
  endfunction


    virtual task body();
         bit [31:0] count;
        REQ rand_pkt;
        rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());

        `uvm_create(req);
        rand_pkt.unaligned_addr.constraint_mode(1);
        rand_pkt.aligned_addr.constraint_mode(0);
      rand_pkt.randomize() with { awburst == WRAP; (awlen+1)*(1<<awsize) > BLOCK_SIZE; };            // Declare block size in common file
        req.copy(rand_pkt);
        req.kind=STIMULUS;
        start_item(req);
        finish_item(req);
        `uvm_info("WRAP WRITE",$sformatf("WRAP len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.awlen+1,req.awaddr),UVM_MEDIUM);
    endtask

endclass



