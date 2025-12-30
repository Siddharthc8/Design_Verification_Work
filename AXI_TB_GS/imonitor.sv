class iMonitor extends uvm_monitor;
`uvm_component_utils(iMonitor)

    virtual axi_intf vif;
    uvm_analysis_port #(transaction) analysis_port;
    transaction tr;
  
    bit[ADDR_WIDTH-1:0] next_starting_addr;

    function new(string name="iMonitor",uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
	super.build_phase(phase);
      
        analysis_port=new("analysis_port",this);
      	if(!uvm_config_db #(virtual axi_intf)::get( this, "" , "VIF", vif)) 
          `uvm_fatal(get_type_name(),"iMonitor DUT interface not set");
      
	endfunction

      
    task run_phase(uvm_phase phase);
    	super.run_phase(phase);
      forever begin
        @(vif.cb_mon);
        fork
          write_channel();
        join_any
      end
  	endtask
   
      
      
    task write_channel();

    //----------------------------------------------------------------------------------------//
    //                                ADDR WRITE CHANNEL                                        
    //----------------------------------------------------------------------------------------//

          `uvm_info(get_type_name(), "Waiting for awvalid and awready", UVM_HIGH);

          wait(vif.cb_mon.awready==1  && vif.cb_mon.awvalid==1);

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
      
          next_starting_addr = tr.awaddr;

          tr.awaddr_q.delete();
          tr.wstrb_q.delete();

          if(tr.burst_type == WRAP)
            tr.calculate_wrap_range(tr.awaddr, tr.awlen, tr.awsize);

        `uvm_info(get_type_name(), $sformatf(" End of waddr channel "), UVM_MEDIUM);

    //----------------------------------------------------------------------------------------//
    //                                 WRITE DATA CHANNEL                                       
    //----------------------------------------------------------------------------------------//

        for(int i = 0; i <= tr.awlen; i++) begin                      //monitor till wlast comes

            // Wait for WVALID first (with timeout)
            wvalid_timeout(i);

            // Wait for wready (with timeout)
            wready_timeout(i);

            // Check if handshake actually completed
            if (vif.cb_mon.wvalid == 1 && vif.cb_mon.wready == 1) begin

                // Sample all signals at handshake
                tr.wvalid = vif.cb_mon.wvalid;
                tr.wdata  = vif.cb_mon.wdata;
                tr.wstrb  = vif.cb_mon.wstrb;

                if(i == tr.awlen) begin
                      tr.wlast = vif.cb_mon.wlast;
                end

                case(tr.awburst)

                  INCR: begin		
                      tr.awaddr_q.push_back(next_starting_addr);
                      next_starting_addr =  incr_addr_calc(next_starting_addr, tr.awsize);
                  end

                  WRAP: begin
                      tr.awaddr_q.push_back(next_starting_addr);
                      next_starting_addr =  incr_addr_calc(next_starting_addr, tr.awsize);
                      tr.check_wrap(next_starting_addr)
                  end

                endcase

            end

              `uvm_info(get_type_name(), $sformatf(" End of wdata channel "), UVM_MEDIUM);

      //----------------------------------------------------------------------------------------//
      //                                 WRITE RESPONSE CHANNEL                                  
      //----------------------------------------------------------------------------------------// 

          wait (vif.cb_mon.bvalid == 1 && vif.cb_mon.bready == 1) ;
          tr.bresp=vif.cb_mon.bresp;
              `uvm_info(get_type_name(), $sformatf(" End of bresp channel "), UVM_LOW);


          analysis_port.write(tr);
          `uvm_info( get_type_name(), $sformatf(" Send tr to scoreboard from iMonitor "), UVM_MEDIUM);

      end

    endtask



    function bit[31:0]  incr_addr_calc(bit [31:0] addr, bit [1:0] size);
      // int count = 0
      // int lane;
      // int offset;
      // count = $countones(wstrb)
      // return addr + count;
      addr = addr + 2**size;
      return addr;
    endfunction

    task wvalid_timeout(input int i);
      fork
        begin
            wait (vif.cb_mon.wvalid == 1);
        end
        begin
            repeat(WVALID_TIMEOUT) @(vif.cb_mon);
            `uvm_fatal(get_type_name(), $sformatf("Timeout waiting for WVALID on beat %0d", i));
        end
      join_any
      disable fork;

      `uvm_info(get_type_name(), $sformatf("WVALID asserted for beat %0d, waiting for WREADY", i), UVM_LOW);
    endtask

    task wready_timeout(input int i);
      fork
        begin
            wait (vif.cb_mon.wvalid == 1 && vif.cb_mon.wready == 1);
        end
        begin
            repeat(WREADY_TIMEOUT) @(vif.cb_mon);
            `uvm_error(get_type_name(), $sformatf("Timeout: WREADY never asserted for beat %0d", i));
        end
      join_any
      disable fork;
    endtask

endclass
      
	
        
        
        
        
        
        
        
        
        
        
        
        
        
/*


task iMonitor::write_channel();

//----------------------------------------------------------------------------------------//
//                                ADDR WRITE CHANNEL                                        
//----------------------------------------------------------------------------------------//
    
    `uvm_info(get_type_name(), "Waiting for awvalid and awready", UVM_HIGH);
  
    wait(vif.cb_mon.awready==1  && vif.cb_mon.awvalid==1);
  
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
    next_starting_addr = tr.awaddr;

    tr.awaddr_q.delete();
    tr.wstrb_q.delete();
 
  `uvm_info(get_type_name(), $sformatf(" End of waddr channel "), UVM_MED);

//----------------------------------------------------------------------------------------//
//                                 WRITE DATA CHANNEL                                       
//----------------------------------------------------------------------------------------//
  
  for(int i = 0; i <= tr.awlen; i++) begin                      //monitor till wlast comes

          // Wait for WVALID first (with timeout)
      fork
          begin
              wait (vif.cb_mon.wvalid == 1);
          end
          begin
              repeat(WVALID_TIMEOUT) @(vif.cb_mon);
              `uvm_fatal(get_type_name(), $sformatf("Timeout waiting for WVALID on beat %0d", i));
          end
      join_any
      disable fork;

        `uvm_info(get_type_name(), $sformatf("WVALID asserted for beat %0d, waiting for WREADY", i), UVM_LOW);

      // Wait for wready (with timeout)
      fork
          begin
              wait (vif.cb_mon.wvalid == 1 && vif.cb_mon.wready == 1);
          end
          begin
              repeat(WREADY_TIMEOUT) @(vif.cb_mon);
              `uvm_error(get_type_name(), $sformatf("Timeout: WREADY never asserted for beat %0d", i));
          end
      join_any
      disable fork;

      // Check if handshake actually completed
      if (vif.cb_mon.wvalid == 1 && vif.cb_mon.wready == 1) begin
        
          // Sample all signals at handshake
          tr.wvalid = vif.cb_mon.wvalid;
          tr.wdata  = vif.cb_mon.wdata;
          tr.wstrb  = vif.cb_mon.wstrb;
        
          if(i == tr.awlen) begin
                tr.wlast = vif.cb_mon.wlast;
          end
        
          case(tr.awburst)
            
            INCR: begin		
                tr.awaddr_q.push_back(next_starting_addr);
                next_starting_addr =  incr_addr_calc(next_starting_addr);
            end
            
            WRAP: begin
              //......//
            end
            
          endcase

      end

        `uvm_info(get_type_name(), $sformatf(" End of wdata channel "), UVM_MED);

//----------------------------------------------------------------------------------------//
//                                 WRITE RESPONSE CHANNEL                                  
//----------------------------------------------------------------------------------------// 
                                         
    wait (vif.cb_mon.bvalid == 1 && vif.cb_mon.bready == 1) ;
    tr.bresp=vif.cb_mon.bresp;
        `uvm_info(get_type_name(), $sformatf(" End of bresp channel "), UVM_LOW);


    analysis_port.write(tr);
    `uvm_info( get_type_name(), $sformatf(" Send tr to scoreboard from iMonitor "), UVM_MED);

end
        
endtask



function bit[31:0]  iMonitor::incr_addr_calc(bit [31:0] addr);
  for(int j = 0; j < 2**tr.awsize; j++) 
    if(tr.wstrb[j]) addr++;
  return addr;
endfunction


                                     
                                     
 
*/                                     
                                     
                                     
                                     
                                     
                                     
                                     
/*                                  
-------------------------------------------------------------------------------------------------------------------------------

// For scoreboard 


awsize =1,awaddr=0

0 -> 0000 ab cd    AB_CD_EF_GH
function void write_to_mem;
	addr = awaddr_q[i]
	if(wstrb_q[0]) begin
		mem[addr] = wdata[7:0];
	if(wstrb_q[1]) begin
		mem[addr+1] = wdata[15:8];
	if(wstrb_q[2]) begin
		mem[addr+2] = wdata[23:16];
if(wstrb_q[3]) begin
		mem[addr+3] = wdata[31:24];
endfunction


{mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]}= rdata_q[i]


*/

