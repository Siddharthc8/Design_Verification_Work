class oMonitor extends uvm_monitor;
`uvm_component_utils(oMonitor)

virtual axi_if.tb_mon vif;
uvm_analysis_port #(transaction) analysis_port;
transaction trans;

function new(string name="oMonitor",uvm_component parent);
	super.new(name,parent);
endfunction

extern virtual function void build_phase(uvm_phase phase);
extern virtual function void connect_phase(uvm_phase phase);
extern virtual task run_phase(uvm_phase phase);

endclass

function void oMonitor ::build_phase(uvm_phase phase);
	super.build_phase(phase);
	analysis_port=new("analysis_port",this);
endfunction

function void oMonitor ::connect_phase(uvm_phase phase);
	super.connect_phase(phase);
  if(!uvm_config_db #(virtual axi_if.tb_mon) :: get(this,"","oMon_if",vif)) begin
		`uvm_fatal(get_type_name(),"oMonitor DUT interface not set");
	end
endfunction

task oMonitor ::run_phase(uvm_phase phase);
    super.run_phase (phase);
   
    forever begin
        @(vif.cb_mon);  
 
        if(vif.cb_mon.reset==0) begin
            trans=transaction::type_id::create("trans",this);
  //address read
            wait(vif.cb_mon.arvalid == 1 && vif.cb_mon.arready==1);
            trans.arlen     = vif.cb_mon.arlen;
            trans.araddr_arr = new[trans.arlen+1];
            trans.rdata_arr    = new[trans.arlen+1];
            trans.araddr_arr[0] = vif.cb_mon.araddr;
       
//read data & resp
            for(int i=0;i<=trans.arlen;i++) begin
            wait(vif.cb_mon.rvalid == 1 && vif.cb_mon.rready==1);
            if(i)  trans.araddr_arr[i]=trans.araddr_arr[i-1]+4;      // You will tell trans.awaddr[i]=vif.cb.next_addr
            trans.wstrb=vif.cb_mon.wstrb;
            trans.rdata_arr[i]=vif.cb_mon.rdata;
            trans.rresp_arr[i]=vif.cb_mon.rresp;
            @(vif.cb_mon);               
            end

            analysis_port.write(trans);
            `uvm_info("oMon",$sformatf( " READ TRANSFER with burst len=%0d addr : %0p data : %0p completed",trans.arlen +1 ,trans.araddr_arr, trans.rdata_arr),UVM_MEDIUM);
 
 end
 end
endtask


    
