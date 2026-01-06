class driver extends uvm_driver #(transaction);

`uvm_component_utils(driver)

    virtual  axi_intf  vif;
    semaphore wa_smp = new(1);
    semaphore wd_smp = new(1);
    semaphore wr_smp = new(1);
  	semaphore ra_smp = new(1);
    semaphore rd_smp = new(1);

  function new(string name ="driver", uvm_component parent = null);
	  super.new(name,parent);
  endfunction


    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      if( !uvm_config_db#(virtual axi_intf)::get(this, "", "VIF", vif) )
        `uvm_fatal(get_type_name(), "Driver interface not set");
      
    endfunction

    task run_phase(uvm_phase phase);
      super.run_phase(phase);

        forever begin

            seq_item_port.get_next_item(req);
            if(req.kind==STIMULUS||req.kind==RESET )
                `uvm_info(get_type_name(),$sformatf("Driver received %0s transaction from TLM port",req.kind.name()),UVM_MEDIUM);

                if(req.kind==RESET) reset();
                else if(req.kind==STIMULUS) drive(req); 

            seq_item_port.item_done();
            `uvm_info(get_type_name(),$sformatf("Driver transaction done"),UVM_MEDIUM);

        end

    endtask

    task reset();
      `uvm_info("Reset_PKT","Applying Reset transction into DUT",UVM_MEDIUM);
          vif.cb.awvalid    <=    0;
          vif.cb.wvalid     <=    0;
          vif.cb.bready     <=    0;
          vif.cb.arvalid    <=    0;
          vif.cb.rready     <=    0;
          vif.cb.reset     <=    1;
          repeat(2) @(vif.cb);
          vif.cb.reset     <=    0;
      `uvm_info("Reset_PKT"," Reset transaction done",UVM_MEDIUM);

      //awaddr, awid, awvalid, awburst, awlen, awsize, awprot, awcache, 
      //wdata,wid,wvalid
      //bready, → drive all inputs to DUT to 0

    endtask

    task drive(transaction tr);

        fork 
            `uvm_info(get_type_name(), "Driving tx", UVM_MEDIUM);
            begin
                if (tr.wr_en == 1) begin
                    write_address(tr);
                    write_data(tr);
                    write_response(tr);
                end
            end
            
            begin
                if(tr.rd_en == 1) begin
                    read_address(tr);
                    read_data(tr);
                end
            end
            
        join
      disable fork;

    endtask


    task write_address(transaction tr);

        wa_smp.get(1);     // Semaphore GET

        @(vif.cb);
        `uvm_info("Driver-write",$sformatf("WRITE ADDRESS BUS started with addr=%0d",tr.awaddr),UVM_DEBUG);
        vif.cb.awid       <=     tr.awid;
        vif.cb.awaddr     <=     tr.awaddr;
        vif.cb.awlen      <=     tr.awlen;
        vif.cb.awsize     <=     tr.awsize;
        vif.cb.awburst    <=     tr.awburst;
        vif.cb.awlock     <=     tr.awlock;
        vif.cb.awcache    <=     tr.awcache;
        vif.cb.awprot     <=     tr.awprot;
        vif.cb.awvalid    <=     1;

          wait(vif.cb.awready==1);

        `uvm_info("Driver-write",$sformatf("WRITE ADDRESS BUS completed with addr=%0d",tr.awaddr),UVM_DEBUG);

        wa_smp.put(1);     // Semaphore PUT

        @(vif.cb);
        
        reset_write_addr_channel();
        

    endtask

    //████████████████████████████████████████████████████████████
    // Write data count is not assigned any value so check in the code below
    //████████████████████████████████████████████████████████████
    task write_data(transaction tr);
        // int temp = 0;
        `uvm_info("Driver-write",$sformatf("WRITE DATA BUS started with AWBURST=%0d",tr.awburst),UVM_DEBUG);

        wd_smp.get(1);

        for(int i = 0; i<=tr.awlen; i++) begin
            
            @(vif.cb);

            vif.cb.wid          <=     tr.wid;
            vif.cb.wdata        <=     $urandom_range(1,1000);
            vif.cb.wstrb        <=     tr.wstrb; 
            // vif.cb.wvalid <= 0;
            //temp = $urandom_range(0,10);           
            // repeat(temp) @(vif.cb);            
            vif.cb.wlast        <=     (i == tr.awlen) ? 1 : 0;  
            vif.cb.wvalid       <=     1;

            wait(vif.cb.wready==1);

          // —---------------- @(vif.cb); vif.cb.wvalid <= 0;
        end

        wd_smp.put(1);

        @(vif.cb);
        reset_write_data_channel();

        `uvm_info("Driver-write",$sformatf("WRITE DATA BUS completed with AWBURST=%0d",tr.awburst),UVM_DEBUG);

    endtask

    task write_response(transaction tr);
        wr_smp.get(1); 
        `uvm_info("Driver-write", $sformatf("WRITE RESPONSE BUS started "), UVM_DEBUG);
        while(vif.bvalid == 0) begin
            @(vif.cb);
        end
        vif.cb.bready     <= 1;
        @(vif.cb);
        vif.cb.bready     <= 0;
        @(vif.cb);
        `uvm_info("Driver-write", $sformatf("WRITE RESPONSE BUS ended "), UVM_DEBUG);
        wr_smp.put(1);
    endtask

     task read_address(transaction tr);
        
        ra_smp.get(1);

       	@(vif.cb);
        `uvm_info("Driver-read",$sformatf("READ ADDRESS BUS started with addr=%0d",tr.araddr),UVM_DEBUG);

          vif.cb.arid       <=     tr.arid;
          vif.cb.araddr     <=     tr.araddr;
          vif.cb.arlen      <=     tr.arlen;
          vif.cb.arsize     <=     tr.arsize;
          vif.cb.arburst    <=     tr.arburst;
          vif.cb.arlock     <=     tr.arlock;
          vif.cb.arcache    <=     tr.arcache;
          vif.cb.arprot     <=     tr.arprot;
          vif.cb.arvalid    <=     1;
          wait(vif.cb.arready==1);

          ra_smp.put(1);

          @(vif.cb);
          reset_read_addr_channel();
        `uvm_info("Driver-read", $sformatf("READ ADDRESS BUS completed with addr=%0d", tr.araddr), UVM_DEBUG);

    endtask

     task read_data(transaction tr);

        rd_smp.get(1);

        repeat(tr.arlen+1) begin
            @(vif.cb);
            `uvm_info("Driver-read", $sformatf("READ DATA BUS started with AWBURST=%0d", tr.awburst), UVM_DEBUG);
            wait(vif.cb.rvalid==1);
            vif.cb.rready     <=  1;
            @(vif.cb);
            vif.cb.rready     <=  0;
        end

        rd_smp.put(1);

     endtask


//     -------   RESET TASKS ----------    // 

    task reset_write_addr_channel();

        vif.cb.awid       <=    0; 
        vif.cb.awaddr     <=    0; 
        vif.cb.awlen      <=    0; 
        vif.cb.awsize     <=    0; 
        vif.cb.awburst    <=    0; 
        vif.cb.awlock     <=    0; 
        vif.cb.awcache    <=    0; 
        vif.cb.awprot     <=    0; 
        vif.cb.awvalid    <=    0; 

    endtask

    task reset_write_data_channel();

        vif.cb.wdata     <=     0;
        vif.cb.wstrb     <=     0;
        vif.cb.wid       <=     0;
        vif.cb.wvalid    <=     0;
        vif.cb.wlast     <=     0;

    endtask
  
  	task reset_read_addr_channel();

        vif.cb.arid       <=    0; 
        vif.cb.araddr     <=    0; 
        vif.cb.arlen      <=    0; 
        vif.cb.arsize     <=    0; 
        vif.cb.arburst    <=    0; 
        vif.cb.arlock     <=    0; 
        vif.cb.arcache    <=    0; 
        vif.cb.arprot     <=    0; 
        vif.cb.arvalid    <=    0; 

    endtask

endclass


