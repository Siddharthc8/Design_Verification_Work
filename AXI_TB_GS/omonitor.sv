class oMonitor extends uvm_monitor;
`uvm_component_utils(oMonitor)

    virtual axi_intf vif;
    uvm_analysis_port #(transaction) analysis_port;
    transaction tr;
    bit[ADDR_WIDTH-1:0] next_starting_addr;

    function new(string name="iMonitor",uvm_component parent);
        super.new(name,parent);
    endfunction

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual task read_channel();
//     extern virtual task write();
    extern virtual task rvalid_timeout(input int i);
    extern virtual task rready_timeout(input int i);

endclass
      
      

    function void oMonitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    
        analysis_port = new( "analysis_port", this );
        if(!uvm_config_db #(virtual axi_intf) :: get(this, "", "VIF", vif)) 
            `uvm_fatal(get_type_name(),"oMonitor DUT interface not set");
    
    endfunction

    task oMonitor::run_phase(uvm_phase phase);
    super.run_phase(phase);
        forever begin
            @(vif.cb_mon);
            read_channel();		
        end	
    endtask

    task oMonitor::read_channel();

//-----------------------------------------------------------//
//                  ADDR READ CHANNEL           
//-----------------------------------------------------------//

        wait (vif.cb_mon.arvalid == 1) ;

        tr = transaction::type_id::create("tr");

        tr.arid    = vif.cb_mon.arid;
        tr.araddr  = vif.cb_mon.araddr;
        tr.arlen   = vif.cb_mon.arlen;
        tr.arsize  = vif.cb_mon.arsize;
        tr.arburst = vif.cb_mon.arburst;
        tr.arlock  = vif.cb_mon.arlock;
        tr.arcache = vif.cb_mon.arcache;
        tr.arprot  = vif.cb_mon.arprot;
        tr.arvalid = vif.cb_mon.arvalid;

        next_starting_addr = tr.araddr;

        `uvm_info(get_type_name(), "Waiting for arready and arvalid", UVM_LOW);
        wait(vif.cb_mon.arvalid == 1  && vif.cb_mon.arready == 1);	


//-----------------------------------------------------------//
//                  DATA READ CHANNEL           
//-----------------------------------------------------------//

    for(int i=0;i <=tr.arlen;i++) begin //monitor till rlast comes

        // Wait for RVALID first (with timeout)
        // rvalid_timeout(i);

        // Wait for RREADY (with timeout)
        // rready_timeout(i);

        // Check if handshake actually completed
        if (vif.cb_mon.rvalid == 1 && vif.cb_mon.rready == 1) begin
            // Sample all signals at handshake
            tr.rvalid = vif.cb_mon.rvalid;
            tr.rdata  = vif.cb_mon.rdata;

            tr.rrespQ.push_back(vif.cb_mon.rresp);
            tr.rdataQ.push_back(vif.cb_mon.rdata);

            if(i == tr.arlen) 
                tr.rlast = vif.cb_mon.rlast;
                analysis_port.write(tr);
            
        end

        `uvm_info( get_type_name(), $sformatf(" Send tr to scoreboard from iMonitor "), UVM_MEDIUM);
    end
                    
    endtask


    task oMonitor::rvalid_timeout(input int i);
    fork
        begin
            wait (vif.cb_mon.rvalid == 1);
        end
        begin
            repeat(RVALID_TIMEOUT) @(vif.cb_mon);
            `uvm_fatal(get_type_name(), $sformatf("Timeout waiting for RVALID on beat %0d", i))
        end
    join_any
    disable fork;

    `uvm_info(get_type_name(), $sformatf("RVALID asserted for beat %0d, waiting for RREADY", i), UVM_LOW);
    endtask

    task oMonitor::rready_timeout(input int i);
    fork
        begin
            wait (vif.cb_mon.rvalid == 1 && vif.cb_mon.rready == 1);
        end
        begin
            repeat(RREADY_TIMEOUT) @(vif.cb_mon);
            `uvm_error(get_type_name(), $sformatf("Timeout: RREADY never asserted for beat %0d", i))
        end
    join_any
    disable fork;
    endtask




