class iMonitor extends uvm_monitor;

    `uvm_component_utils(iMonitor)

    virtual axi_intf vif;
    uvm_analysis_port #(transaction) analysis_port;
    transaction tr;

    bit [ADDR_WIDTH-1:0] next_starting_addr;

    function new(string name = "iMonitor", uvm_component parent);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        analysis_port = new("analysis_port", this);

        if (!uvm_config_db #(virtual axi_intf)::get(this, "", "VIF", vif))
            `uvm_fatal(get_type_name(), "iMonitor DUT interface not set");
    endfunction


    task run_phase(uvm_phase phase);
        super.run_phase(phase);

        forever begin
            @(vif.cb_mon);
            fork
                write_channel();
            join
        end
    endtask


    task write_channel();

        //------------------------------------------------------------------------------------//
        //                                ADDR WRITE CHANNEL                                   //
        //------------------------------------------------------------------------------------//

        `uvm_info(get_type_name(), "Waiting for awvalid and awready", UVM_HIGH);

        wait (vif.cb_mon.awready == 1 && vif.cb_mon.awvalid == 1);

        tr = transaction::type_id::create("tr");

        tr.awid    = vif.cb_mon.awid;
        tr.awaddr  = vif.cb_mon.awaddr;
        tr.awlen   = vif.cb_mon.awlen;
        tr.awsize  = vif.cb_mon.awsize;
        tr.awburst = vif.cb_mon.awburst;
        tr.awlock  = vif.cb_mon.awlock;
        tr.awcache = vif.cb_mon.awcache;
        tr.awprot  = vif.cb_mon.awprot;
        tr.awvalid = vif.cb_mon.awvalid;

        tr.wdataQ.delete();
        tr.wstrbQ.delete();

        `uvm_info(get_type_name(), "End of write addr channel", UVM_MEDIUM);

        //------------------------------------------------------------------------------------//
        //                                WRITE DATA CHANNEL                                   //
        //------------------------------------------------------------------------------------//

        for (int i = 0; i <= tr.awlen; i++) begin

            // Wait for WVALID first (with timeout)
            wvalid_timeout(i);

            // Wait for WREADY and WVALID (with timeout)
            wready_timeout(i);

            if (vif.cb_mon.wvalid == 1 && vif.cb_mon.wready == 1) begin

                tr.wid   = vif.cb_mon.wid;
                tr.wdata = vif.cb_mon.wdata;
                tr.wstrb = vif.cb_mon.wstrb;

                tr.wdataQ.push_back(tr.wdata);
                tr.wstrbQ.push_back(tr.wstrb);

                if (i == tr.awlen)
                    tr.wlast = vif.cb_mon.wlast;

            end

            `uvm_info(get_type_name(), "End of wdata channel", UVM_MEDIUM);

            //--------------------------------------------------------------------------------//
            //                              WRITE RESPONSE CHANNEL                              //
            //--------------------------------------------------------------------------------//

            wait (vif.cb_mon.bvalid == 1 && vif.cb_mon.bready == 1);

            tr.bresp = vif.cb_mon.bresp;

            `uvm_info(get_type_name(), "End of bresp channel", UVM_LOW);

            analysis_port.write(tr);

            `uvm_info(
                get_type_name(),
                "Send tr to scoreboard from iMonitor",
                UVM_MEDIUM
            );

            @(vif.cb_mon);

        end
    endtask


    task wvalid_timeout(input int i);
        fork
            begin
                wait (vif.cb_mon.wvalid == 1);
            end
            begin
                repeat (WVALID_TIMEOUT) @(vif.cb_mon);
                `uvm_fatal(
                    get_type_name(),
                    $sformatf("Timeout waiting for WVALID on beat %0d", i)
                );
            end
        join_any
        disable fork;

        `uvm_info(
            get_type_name(),
            $sformatf("WVALID asserted for beat %0d, waiting for WREADY", i),
            UVM_LOW
        );
    endtask


    task wready_timeout(input int i);
        fork
            begin
                wait (vif.cb_mon.wvalid == 1 && vif.cb_mon.wready == 1);
            end
            begin
                repeat (WREADY_TIMEOUT) @(vif.cb_mon);
                `uvm_error(
                    get_type_name(),
                    $sformatf("Timeout: WREADY never asserted for beat %0d", i)
                );
            end
        join_any
        disable fork;
    endtask

endclass
