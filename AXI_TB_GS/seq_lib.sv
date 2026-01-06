//    SEQUENCES     //


class axi_base_seq extends uvm_sequence#(transaction);
`uvm_object_utils(axi_base_seq)

    uvm_phase phase;
    transaction trQ[$];
    transaction tr;

    `NEW_OBJ

    task pre_body();
        phase = get_starting_phase();
        if(phase != null) begin
            phase.raise_objection(this);
            phase.phase_done.set_drain_time(this, 100);
        end
    endtask

    task post_body();
        if(phase != null)
            phase.drop_objection(this);
    endtask


endclass


class axi_n_wr_n_rd_seq extends axi_base_seq;
`uvm_object_utils(axi_n_wr_n_rd_seq)

    int count;

    `NEW_OBJ

    task body();
        uvm_config_db#(int)::get( null, "", "COUNT", count);

        repeat(count) begin
            `uvm_do_with(req, {
                req.kind     ==   STIMULUS;
                req.wr_en    ==   1;
                req.rd_en    ==   0;
                req.awburst  ==   INCR;
                // req.awvalid  ==   1;
                // req.wvalid   ==   1;
                // req.bready   ==   1;

                req.arid     ==   0;   
                req.araddr   ==   0;   
                req.arlen    ==   0;   
                req.arsize   ==   0;   
                req.arburst  ==   0; 

                // req.arvalid  ==   0;
                // req.rready   ==   0;

            });
            // req.unaligned_addr.constraint_mode(0);
            tr = transaction::type_id::create("tr");
            tr.copy(req);
            trQ.push_back(tr);
        end
        repeat(count) begin
            if(trQ.size() > 0) begin
                tr = trQ.pop_front();
                `uvm_do_with(req, {
                    req.kind     ==   STIMULUS;
                    req.wr_en    ==   0;
                    req.rd_en    ==   1;
                    req.arid     ==   tr.awid;           // Same id
                    req.araddr   ==   tr.awaddr;         // Same address
                    req.arlen    ==   tr.awlen;          // Same burst length
                    req.arsize   ==   tr.awsize;     // Same burst size
                    req.arburst  ==   tr.awburst;     // Same burst type
                    // req.arvalid  ==   1;
                    // req.rready   ==   1;

                    req.awid     ==   0;
                    req.awaddr   ==   0;
                    req.awlen    ==   0;
                    req.awsize   ==   0;
                    req.awburst  ==   0;

                    // req.awvalid  ==   0;
                    // req.wvalid   ==   0;
                    // req.bready   ==   0;
                    });     // No semicolon
                    // req.unaligned_addr.constraint_mode(0);
            end
        end

    endtask

endclass

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




// // ------------------------------- FIXED —--------------------------

// class aligned_write_fixed_sequence extends uvm_sequence #(transaction);
// // typedef transaction REQ; typedef transaction RSP;
// //transaction req;

//     `uvm_object_utils(aligned_write_fixed_sequence) 

//     int item_count;
//       function new(string name = "aligned_write_fixed_sequence");
//         super.new(name);
//         set_automatic_phase_objection(1);
//       endfunction

//     virtual task pre_body();
//       if(!uvm_config_db#(int)::get(get_sequencer(), "", "COUNT",item_count));
//     endtask

//     virtual task body();
//     REQ rand_pkt;
//     rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
//     //function T create (string name = "", uvm_component parent = null, string contxt = "");

//     repeat(item_count) begin
//             `uvm_create(req);
//            rand_pkt.unaligned_addr.constraint_mode(0);
//            rand_pkt.aligned_addr.constraint_mode(1);
//             rand_pkt.randomize() with {awburst==FIXED;};
//             req.copy(rand_pkt);
//             req.kind=STIMULUS;
//             start_item(req);
//             finish_item(req);
//             `uvm_info(" SEQ",$sformatf("FIXED len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.awlen+1,req.awaddr),UVM_MEDIUM);
//         end
//         endtask

// endclass

// class unaligned_write_fixed_sequence extends uvm_sequence #(transaction);
// // typedef transaction REQ; typedef transaction RSP;
// //transaction req;

//     `uvm_object_utils(unaligned_write_fixed_sequence) 

//     int item_count;
//       function new(string name = "unaligned_write_fixed_sequence");
//         super.new(name);
//         set_automatic_phase_objection(1);
//       endfunction

//     virtual task pre_body();
//       if(!uvm_config_db#(int)::get(get_sequencer(), "", "WRITE_COUNT",item_count)); 
//     endtask

//     virtual task body();
//         REQ rand_pkt;
//         rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
//         //function T create (string name = "", uvm_component parent = null, string contxt = "");

//         repeat(item_count) begin
//                 `uvm_create(req);
//                rand_pkt.unaligned_addr.constraint_mode(1);
//                rand_pkt.aligned_addr.constraint_mode(0);
//                 rand_pkt.randomize() with {awburst==FIXED;};
//                 req.copy(rand_pkt);
//                 req.kind=STIMULUS;
//                 start_item(req);
//                 finish_item(req);
//                 `uvm_info(" SEQ",$sformatf("FIXED len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.awlen+1,req.awaddr),UVM_MEDIUM);
//             end
//         endtask

// endclass


// class aligned_read_fixed_sequence extends uvm_sequence #(transaction);
// // typedef transaction REQ; typedef transaction RSP;
// //transaction req;

//     `uvm_object_utils(aligned_read_fixed_sequence) 

//     int item_count;
//       function new(string name = "aligned_read_fixed_sequence");
//         super.new(name);
//         set_automatic_phase_objection(1);
//       endfunction

//     virtual task pre_body();
//       if(!uvm_config_db#(int)::get(get_sequencer(), "", "READ_COUNT",item_count)); 
//     endtask

//     virtual task body();
//       REQ rand_pkt;
//       rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
//       //function T create (string name = "", uvm_component parent = null, string contxt = "");

//       repeat(item_count) begin
//               `uvm_create(req);
//              rand_pkt.unaligned_addr.constraint_mode(0);
//              rand_pkt.aligned_addr.constraint_mode(1);
//               rand_pkt.randomize() with {arburst==FIXED;};
//               req.copy(rand_pkt);
//               req.kind=STIMULUS;
//               start_item(req);
//               finish_item(req);
//               `uvm_info(" SEQ",$sformatf("FIXED len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.arlen+1,req.araddr),UVM_MEDIUM);
//           end
//      endtask

// endclass

// class unaligned_read_fixed_sequence extends uvm_sequence #(transaction);
// // typedef transaction REQ; typedef transaction RSP;
// //transaction req;

//     `uvm_object_utils(unaligned_read_fixed_sequence) 

//     int item_count;
  
//       function new(string name = "unaligned_read_fixed_sequence");
//         super.new(name);
//         set_automatic_phase_objection(1);
//       endfunction

//     virtual task pre_body();
//       if(!uvm_config_db#(int)::get(get_sequencer(), "", "READ_COUNT",item_count));
//     endtask

//     virtual task body();
//         REQ rand_pkt;
//         rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
//         //function T create (string name = "", uvm_component parent = null, string contxt = "");

//         repeat(item_count) begin
//                 `uvm_create(req);
//                rand_pkt.unaligned_addr.constraint_mode(1);
//                rand_pkt.aligned_addr.constraint_mode(0);
//                 rand_pkt.randomize() with {arburst==FIXED;};
//                 req.copy(rand_pkt);
//                 req.kind=STIMULUS;
//                 start_item(req);
//                 finish_item(req);
//                 `uvm_info(" SEQ",$sformatf("FIXED len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.arlen+1,req.araddr),UVM_MEDIUM);
//             end
//      endtask

// endclass


// // -------------------------------INCREMENT-------------------------------

// class aligned_write_incr_sequence extends uvm_sequence #(transaction);
//     `uvm_object_utils(aligned_write_incr_sequence)

//   function new(string name = "aligned_write_incr_sequence");
//     super.new(name);
//     set_automatic_phase_objection(1);
//   endfunction


//   virtual task body();
//        bit [31:0] count;
//       REQ rand_pkt;
//       rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());

//               `uvm_create(req);
//               rand_pkt.unaligned_addr.constraint_mode(0);
//               rand_pkt.aligned_addr.constraint_mode(1);
//               rand_pkt.randomize() with {awburst==INCR;};
//               req.copy(rand_pkt);
//               req.kind=STIMULUS;
//               start_item(req);
//               finish_item(req);
//               `uvm_info("INCR WRITE",$sformatf("INCR len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.awlen+1,req.awaddr),UVM_MEDIUM);
//    endtask

// endclass

// class unaligned_write_incr_sequence extends uvm_sequence #(transaction);
//     `uvm_object_utils(unaligned_write_incr_sequence)

//   function new(string name = "unaligned_write_incr_sequence");
//     super.new(name);
//     set_automatic_phase_objection(1);
//   endfunction


//     virtual task body();
//          bit [31:0] count;
//         REQ rand_pkt;
//         rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());

//         `uvm_create(req);
//         rand_pkt.unaligned_addr.constraint_mode(1);
//         rand_pkt.aligned_addr.constraint_mode(0);
//         rand_pkt.randomize() with {awburst==INCR;};
//         req.copy(rand_pkt);
//         req.kind=STIMULUS;
//         start_item(req);
//         finish_item(req);
//         `uvm_info("INCR WRITE",$sformatf("INCR len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.awlen+1,req.awaddr),UVM_MEDIUM);
//     endtask

// endclass


// class aligned_read_incr_sequence extends uvm_sequence #(transaction);
// // typedef transaction REQ; typedef transaction RSP;
// //transaction req;

//     `uvm_object_utils(aligned_read_incr_sequence) 

//     int item_count;
  
//       function new(string name = "aligned_read_incr_sequence");
//         super.new(name);
//         set_automatic_phase_objection(1);
//       endfunction

//     virtual task pre_body();
//       if(!uvm_config_db#(int)::get(get_sequencer(), "", "READ_COUNT",item_count)); 
//     endtask

//     virtual task body();
//         REQ rand_pkt;
//         rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
//         //function T create (string name = "", uvm_component parent = null, string contxt = "");

//     	repeat(item_count) begin
//             `uvm_create(req);
//            rand_pkt.unaligned_addr.constraint_mode(0);
//            rand_pkt.aligned_addr.constraint_mode(1);
//             rand_pkt.randomize() with {arburst==INCR;};
//             req.copy(rand_pkt);
//             req.kind=STIMULUS;
//             start_item(req);
//             finish_item(req);
//             `uvm_info(" SEQ",$sformatf("INCR len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.arlen+1,req.araddr),UVM_MEDIUM);
//         end
//     endtask

// endclass

// class unaligned_read_incr_sequence extends uvm_sequence #(transaction);
// // typedef transaction REQ; typedef transaction RSP;
// //transaction req;

//     `uvm_object_utils(unaligned_read_incr_sequence) 

// 	int item_count;
  
//   function new(string name = "unaligned_read_incr_sequence");
//     super.new(name);
//     set_automatic_phase_objection(1);
//   endfunction

//   virtual task pre_body();
//     if(!uvm_config_db#(int)::get(get_sequencer(), "", "READ_COUNT",item_count)); 
//   endtask

//   virtual task body();
//       REQ rand_pkt;
//       rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
//       //function T create (string name = "", uvm_component parent = null, string contxt = "");

//       repeat(item_count) begin
//               `uvm_create(req);
//              rand_pkt.unaligned_addr.constraint_mode(0);
//              rand_pkt.aligned_addr.constraint_mode(1);
//               rand_pkt.randomize() with {arburst==INCR;};
//               req.copy(rand_pkt);
//               req.kind=STIMULUS;
//               start_item(req);
//               finish_item(req);
//               `uvm_info(" SEQ",$sformatf("INCR len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.arlen+1,req.araddr),UVM_MEDIUM);
//           end
//     endtask

// endclass


// // ------------------------------- WRAP -------------------------------


// class aligned_write_wrap_sequence extends uvm_sequence #(transaction);
//   `uvm_object_utils(aligned_write_wrap_sequence)

//   function new(string name = "aligned_write_wrap_sequence");
//     super.new(name);
//     set_automatic_phase_objection(1);
//   endfunction


//     virtual task body();
//          bit [31:0] count;
//         REQ rand_pkt;
//         rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());

//         `uvm_create(req);
//         rand_pkt.unaligned_addr.constraint_mode(1);
//         rand_pkt.aligned_addr.constraint_mode(0);
//         rand_pkt.randomize() with {awburst==WRAP;};
//         req.copy(rand_pkt);
//         req.kind=STIMULUS;
//         start_item(req);
//         finish_item(req);
//         `uvm_info("WRAP WRITE",$sformatf("WRAP len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.awlen+1,req.awaddr),UVM_MEDIUM);
//     endtask

// endclass


// class unaligned_write_wrap_sequence extends uvm_sequence #(transaction);//err sequence
//     `uvm_object_utils(unaligned_write_wrap_sequence)

//   function new(string name = "unaligned_write_wrap_sequence");
//     super.new(name);
//     set_automatic_phase_objection(1);
//   endfunction


//     virtual task body();
//          bit [31:0] count;
//         REQ rand_pkt;
//         rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());

//         `uvm_create(req);
//         rand_pkt.unaligned_addr.constraint_mode(1);
//         rand_pkt.aligned_addr.constraint_mode(0);
//         rand_pkt.randomize() with {awburst==WRAP;};
//         req.copy(rand_pkt);
//         req.kind=STIMULUS;
//         start_item(req);
//         finish_item(req);
//         `uvm_info("WRAP WRITE",$sformatf("WRAP len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.awlen+1,req.awaddr),UVM_MEDIUM);
//       endtask

// endclass


// class aligned_read_wrap_sequence extends uvm_sequence #(transaction);
// // typedef transaction REQ; typedef transaction RSP;
// //transaction req;

//     `uvm_object_utils(aligned_read_wrap_sequence) 

// 	int item_count;
  
//   function new(string name = "aligned_read_wrap_sequence");
//     super.new(name);
//     set_automatic_phase_objection(1);
//   endfunction

//     virtual task pre_body();
//       if(!uvm_config_db#(int)::get(get_sequencer(), "", "READ_COUNT",item_count)); 
//     endtask

//     virtual task body();
//         REQ rand_pkt;
//         rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
//         //function T create (string name = "", uvm_component parent = null, string contxt = "");

//     	repeat(item_count) begin
//             `uvm_create(req);
//            rand_pkt.unaligned_addr.constraint_mode(0);
//            rand_pkt.aligned_addr.constraint_mode(1);
//             rand_pkt.randomize() with {arburst==WRAP;};
//             req.copy(rand_pkt);
//             req.kind=STIMULUS;
//             start_item(req);
//             finish_item(req);
//             `uvm_info("WRAP SEQ",$sformatf("WRAP len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.arlen+1,req.araddr),UVM_MEDIUM);
//         end
//     endtask

// endclass


// class unaligned_read_wrap_sequence extends uvm_sequence #(transaction);
// // typedef transaction REQ; typedef transaction RSP;
// //transaction req;

//     `uvm_object_utils( unaligned_read_wrap_sequence) 

//     int item_count;
  
//       function new(string name = " unaligned_read_wrap_sequence");
//         super.new(name);
//         set_automatic_phase_objection(1);
//       endfunction

//     virtual task pre_body();
//       if(!uvm_config_db#(int)::get(get_sequencer(), "", "READ_COUNT",item_count));
//     endtask

//     virtual task body();
//         REQ rand_pkt;
//         rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());
//         //function T create (string name = "", uvm_component parent = null, string contxt = "");

//     	repeat(item_count) begin
//             `uvm_create(req);
//            rand_pkt.unaligned_addr.constraint_mode(0);
//            rand_pkt.aligned_addr.constraint_mode(1);
//             rand_pkt.randomize() with {arburst==WRAP;};
//             req.copy(rand_pkt);
//             req.kind=STIMULUS;
//             start_item(req);
//             finish_item(req);
//             `uvm_info(" SEQ",$sformatf("WRAP len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.arlen+1,req.araddr),UVM_MEDIUM);
//         end
//     endtask

// endclass



// // ERROR WRAP SEQUENCE

// class error_aligned_write_wrap_sequence extends uvm_sequence #(transaction);
//   `uvm_object_utils(aligned_write_wrap_sequence)

//   function new(string name = "aligned_write_wrap_sequence");
//     super.new(name);
//     set_automatic_phase_objection(1);
//   endfunction


//     virtual task body();
//          bit [31:0] count;
//         REQ rand_pkt;
//         rand_pkt=transaction::type_id::create("rand_pkt",,get_full_name());

//         `uvm_create(req);
//         rand_pkt.unaligned_addr.constraint_mode(1);
//         rand_pkt.aligned_addr.constraint_mode(0);
//       rand_pkt.randomize() with { awburst == WRAP; (awlen+1)*(1<<awsize) > BLOCK_SIZE; };            // Declare block size in common file
//         req.copy(rand_pkt);
//         req.kind=STIMULUS;
//         start_item(req);
//         finish_item(req);
//         `uvm_info("WRAP WRITE",$sformatf("WRAP len sequence : Write transfer Done with burst length=%0d ,start ADDR=%0d",req.awlen+1,req.awaddr),UVM_MEDIUM);
//     endtask

// endclass



