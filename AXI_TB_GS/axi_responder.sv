class axi_responder extends uvm_component;
`uvm_component_utils(axi_responder)

    `NEW_COMP

    transaction rd_tx;
    transaction wr_tx;
    virtual axi_intf vif;
    semaphore rd_smp = new(1);

    bit [DATA_WIDTH-1:0] wdata; 
    bit [STRB_WIDTH-1:0] wstrb;

    bit [DATA_WIDTH-1:0] rdata;
    // int unsigned awsize; 

    // bit [DATA_WIDTH-1:0] data_ref;

    bit [DATA_WIDTH-1:0] fifo [$];      // For Fixed
    bit [7:0] mem [*];                       // For wrap and INCR

    int unsigned lane_offset_w;
    int unsigned lane_offset_r;
    int unsigned num_bytes_w;
    int unsigned num_bytes_r;
    int lane_w;
    int lane_r;
    // int unsigned base_addr;

    function void build_phase(uvm_phase phase);
    super.build_phase(phase);
        if(!uvm_config_db#(virtual axi_intf)::get(null, "", "VIF", vif))
            `uvm_error(get_type_name(), "Interface unable to be retrieved");
    endfunction

    virtual task reset_phase(uvm_phase phase);
        super.reset_phase(phase);
        mem.delete();
        `uvm_info(get_type_name(), "Responder memory cleared on reset", UVM_MEDIUM);
    endtask

    task run_phase(uvm_phase phase);
        super.run_phase(phase);

        `uvm_info(get_type_name(), "Run Phase on Responder tx", UVM_MEDIUM);

        forever begin

            @(vif.slave_cb);

            //----------------------------------------------------------------------------------------//
            //                                ADDR WRITE CHANNEL                                        
            //----------------------------------------------------------------------------------------//  

            if(vif.slave_cb.awvalid == 1'b1) begin
                vif.slave_cb.awready <= 1'b1;
                wr_tx = new("wr_tx");
                // Remembering all read addr info
                wr_tx.awid             =     vif.slave_cb.awid;
                wr_tx.awaddr           =     vif.slave_cb.awaddr;
                wr_tx.awlen            =     vif.slave_cb.awlen;
                wr_tx.awsize           =     vif.slave_cb.awsize;
                wr_tx.awburst          =     vif.slave_cb.awburst;
                
                // awsize = wr_tx.burst_size;
                `uvm_info("AWSIZE_DEBUG", $sformatf("Captured awsize = %0d, tx.burst_size = %0d, vif.bursts_size = %0d from interface",wr_tx.awsize, wr_tx.awsize, vif.slave_cb.awsize), UVM_MEDIUM);

                wr_tx.calculate_wrap_range(wr_tx.awaddr, wr_tx.awlen, wr_tx.awsize);
            end
            else begin
                vif.slave_cb.awready <= 1'b0;
            end

            //----------------------------------------------------------------------------------------//
            //                                DATA WRITE CHANNEL                                        
            //----------------------------------------------------------------------------------------//

            if(vif.slave_cb.wvalid == 1'b1) begin
                vif.slave_cb.wready <= 1'b1;
                wr_tx.wid = vif.slave_cb.wid;
                wr_tx.wdata = vif.slave_cb.wdata;
                wr_tx.wstrb = vif.slave_cb.wstrb;

                wdata = wr_tx.wdata;
                wstrb = wr_tx.wstrb;

                // awsize = wr_tx.awsize;
                
                if( wr_tx.awburst inside {INCR, WRAP, FIXED} ) begin
                    
                    `uvm_info(get_type_name(), $sformatf("DATA at responder awsize = %0d, addr = %h, data = %h, strb = %b", wr_tx.awsize, wr_tx.awaddr, wdata, wstrb), UVM_MEDIUM);
                    num_bytes_w = 1 << wr_tx.awsize;
                    lane_offset_w = wr_tx.awaddr % (DATA_WIDTH/8);
                    // `uvm_info("NUM_BYTES_DEBUG", $sformatf("Captured num_bytes_w = %0d, lane_offset_w = %0d, strb_width = %0d", num_bytes_w, lane_offset_w, STRB_WIDTH), UVM_MEDIUM);
                    for (int j = 0; j < num_bytes_w; j++) begin
                        lane_w = lane_offset_w + j;
                        if (wstrb[lane_w]) begin
                            mem[wr_tx.awaddr + j] = wdata[lane_w*8 +: 8];
                            // `uvm_info("MEM_WRITE", $sformatf("j = %0d, mem[%h] = wdata[%0d:%0d], data = %0h",j, wr_tx.addr+j,lane_w*8+8,lane_w*8, wdata[lane_w*8 +: 8]), UVM_DEBUG);
                        end
                    end
                    `uvm_info(get_type_name(), $sformatf("Writing at addr = %h, data = %h, strb = %b", wr_tx.awaddr, wdata, wstrb), UVM_MEDIUM);
                    if( wr_tx.awburst inside {INCR, WRAP} )
                        wr_tx.awaddr += 2**wr_tx.awsize;        // Incrementing the address by the burst_size
                    if(wr_tx.awburst == WRAP)
                        wr_tx.awaddr = wr_tx.check_wrap(wr_tx.awaddr);         // Resets the addr to lower_boundary when it reaches the upper boundary
                end
                // 
                // else if( wr_tx.burst_type == FIXED ) begin
                //     fifo.push_back( vif.slave_cb.wdata ); 
                // end
                else begin
                    `uvm_error("WRITE RSVD_BURST_TYPE_ERROR", $sformatf("WRITE BURST_TYPE is neither INCR, WRAP, or FIXED"));
                end
            
                if(vif.slave_cb.wlast == 1) begin   // wlast and wvalid also should be high
                    write_resp_phase( wr_tx.wid );
                end
            end
            else begin
                vif.slave_cb.wready <= 1'b0;
            end
            

            //----------------------------------------------------------------------------------------//
            //                                ADDR READ CHANNEL                                        
            //----------------------------------------------------------------------------------------//

            if(vif.slave_cb.arvalid == 1'b1) begin
                vif.slave_cb.arready <= 1'b1;
                rd_tx = new("rd_tx");
                // Remembering all read addr info
                rd_tx.arid        =     vif.slave_cb.arid;
                rd_tx.araddr      =     vif.slave_cb.araddr;
                rd_tx.arlen       =     vif.slave_cb.arlen;
                rd_tx.arsize      =     vif.slave_cb.arsize;
                rd_tx.arburst     =     vif.slave_cb.arburst;
                rd_tx.calculate_wrap_range(rd_tx.araddr, rd_tx.arlen, rd_tx.arsize);

                fork
                    read_data_phase(rd_tx);
                join_none

            end
            else begin
                vif.slave_cb.arready <= 1'b0;
            end
        end

    endtask


    task write_resp_phase(bit [3:0] id);
        // @(vif.slave_cb);
        vif.slave_cb.bid           <=      id;
        vif.slave_cb.bresp         <=      OKAY;
        vif.slave_cb.bvalid        <=      1;
        wait(vif.slave_cb.bready == 1);

        @(vif.slave_cb);

        vif.slave_cb.bid           <=      0;
        vif.slave_cb.bresp         <=      0;
        vif.slave_cb.bvalid        <=      0;
         
    endtask


    task read_data_phase(transaction rd_tx);

        int rd_delay;

        // rd_delay = $urandom_range(5,20);
        // repeat(rd_delay) @(vif.slave_cb);

        rd_smp.get(1);
        for(int i = 0; i <= rd_tx.arlen; i++) begin

            // rd_smp.get(1);         // Semaphore to control overwriting on the read data channel

            @(vif.slave_cb);
            
            if( rd_tx.arburst inside {INCR, WRAP, FIXED} ) begin

                lane_offset_r = rd_tx.araddr % (DATA_WIDTH/8);
                rdata = '0;
                for(int j = 0; j < 2**rd_tx.arsize; j++) begin
                    int lane_r = lane_offset_r + j;
                    rdata[lane_r*8 +: 8] = mem[rd_tx.araddr + j];  // Cleaner bit slice assignment
                end

                vif.slave_cb.rdata     <=      rdata;
                `uvm_info(get_type_name(), $sformatf("Reading to intf at addr = %h, data = %h", rd_tx.araddr, rdata), UVM_MEDIUM);

                if( rd_tx.arburst inside {INCR, WRAP} )
                    rd_tx.araddr    +=      2**rd_tx.arsize;  
                if(rd_tx.arburst == WRAP)        
                    rd_tx.araddr = rd_tx.check_wrap(rd_tx.araddr);                                  // Resets the addr to lower_boundary when it reaches the upper boundary
            end
            // else if( rd_tx.burst_type == FIXED ) begin
            //     rdata = fifo.pop_front();
            //     vif.slave_cb.rdata     <=      rdata;
            //     `uvm_info(get_type_name(), $sformatf("Reading at addr = %h, data = %h", rd_tx.addr, rdata), UVM_MEDIUM);
            // end
            else begin
                `uvm_error("READ RSVD_BURST_TYPE_ERROR", $sformatf("READ BURST_TYPE is neither INCR, WRAP, or FIXED"));
            end

            vif.slave_cb.rid       <=      rd_tx.rid;
            vif.slave_cb.rlast     <=      (i == rd_tx.arlen) ? 1 : 0;
            vif.slave_cb.rvalid    <=      1'b1;

            wait(vif.slave_cb.rready == 1);

            // rd_smp.put(1);              // Semaphore to control overwriting on the read data channel
        end
        rd_smp.put(1); 
        @(vif.slave_cb);               

        reset_read_data();

    endtask

    task reset_read_data();

        vif.slave_cb.rdata     <=      0;
        vif.slave_cb.rid       <=      0;
        vif.slave_cb.rlast     <=      0;
        vif.slave_cb.rvalid    <=      0;

    endtask

endclass //