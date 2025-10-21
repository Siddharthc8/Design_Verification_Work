
typedef enum {STIMULUS,RESET} kind_type;
typedef enum {WRITE,READ} oper_type;

//transaction class
kind_type kind;
oper_type oper; 

// APB DRIVER

class apb_driver extends uvm_driver;
int count;
task run_phase(uvm_phase phase);
super.new(phase);

forever begin
	
seq_item_port.get_next_item(req);

  if(req.kind == RESET) 
`uvm_info(“DRV”, $sformat(“Received  %0s    seq_item”,req.kind.name()),UVM_MEDIUM);
	
else if (req.kind==STIMULUS)
`uvm_info(“DRV”, $sformat(“Received %0d     with %0s  :%0s seq_item packet”,  ++count, req.kind.name(), req.oper.name()), UVM_MEDIUM);


else `uvm_fatal (“Unknown transaction received”);

drive(req);
seq_item_port.item_done();
end

endtask

task drive(transaction tr);
case (tr.kind) 
RESET: reset();
STIMULUS : drive_stimulus(tr);
endcase
endtask

task reset();
//Display Reset start
vif.cb.psel <=1’b0;
vif.cb.penable <=1’b0;
vif.cb.pwrite <=1’b0;
vif.cb.paddr<=1’b0;
vif.cb.pwdata <=1’b0;
vif.cb.presetn <=1’b0;
repeat(3) @(vif.cb);
vif.cb.presetn <=1’b1;

//Display Reset End

endtask


// Drive Task
task drive_stimulus(transaction tr);
if(tr.oper==WRITE || tr.oper==READ ) begin
//display write/read transaction started
// Setup phase
@(vif.cb);
vif.cb.presetn <=1’b1;
vif.cb.psel<=1’b1;
vif.cb.penable <=1’b0;
vif.cb.pwrite<=tr.pwrite;//1
vif.cb.paddr <=tr.paddr;
vif.cb.pwdata <=tr.wdata;

// Access phase
 @(vif.cb);
vif.cb.penable <=1’b1;

//  —-> way 1            //  Correct and Preferred
wait(vif.cb.pready==1) ;
@(vif.cb) ; //pready will become 0          
vif.cb.penable <=1’b0;  


//   —> way 2           // This is not a preferred method

@(posedge vif.cb.pready); //
@(vif.cb);                            
vif.cb.penable <=1’b0; 


//   —> way 3        // This is wrong

@(negedge vif.cb.pready); //
@(vif.cb);                            
vif.cb.penable <=1’b0; 


//display write/read transaction ended

end

else //display error

endtask




// APB MONITOR

// IN Monitor

Psel                —-> ctrl sg
Penable         —--> ctrl sg
Pwrite             —-> ctrl sg
Paddr          
Pwdata          —--->  I/P monitor


Prdata           —--->   O/P monitor
Pready          —-> ctrl sg
Pslverr           —---> O/P monitor   ctrl sg

class ip_monitor extends uvm_monitor;
transaction tr ;

task run_phase(uvm_phase phase);
forever begin
wait(vif.cb.sel==1 && vif.cb.penable == 1’b1);
if(vif.cb.pwrite == 1) begin
	tr=new;
	tr.paddr=vif.cb.paddr;	
	tr.pwdata=vif.cb.pwdata;
	tr.pwrite=vif.cb.pwrite;
	ap.write(tr);
//display saying I’m sending the write transaction(addr,pwdata) to scb
end
else if(vif.cb.pwrite==0) 
//display saying I received  a read  transaction(addr) to scb	

wait(vif.cb.pready==1);
—------------------
@(vif.cb);

end
endtask

endclass
// OUT  Monitor

Psel                —-> ctrl sg
Penable         —--> ctrl sg
Pwrite             —-> ctrl sg
Paddr          
Pwdata          —--->  I/P monitor


Prdata           —--->   O/P monitor
Pready          —-> ctrl sg
Pslverr           —---> O/P monitor   ctrl sg

class op_monitor extends uvm_monitor;
transaction tr ;

task run_phase(uvm_phase phase);
forever begin

wait(vif.cb.sel==1 && vif.cb.penable == 1’b1);

wait(vif.cb.pready==1);

if(vif.cb.pwrite == 0) begin
	tr=new;
	tr.paddr = vif.cb.paddr;	
	tr.prdata = vif.cb.prdata;
	tr.pwrite = vif.cb.pwrite;
	tr.pslverr = vif.cb.pslverr;
	ap.write(tr);
//display saying I’m sending the read transaction(addr,prdata),vif.sb.error to scb`
if(tx.pslverr == 1) `uvm_error(“MON”, “$sformatf(“There is an error %b”, tx.pslverr));

end

if(vif.cb.pwrite==1) 
//display saying I received a write transaction(addr), vif.cb.pslverr  to scb	


end

endtask

endclass

------------------------------------------------------

//Scoreboard

------------------------------------------------------


 class out_of_order_scoreboard #(type T=packet) extends uvm_scoreboard;

//Section S2 : create scb_type typed to out_of_order_scoreboard#(T)
typedef out_of_order_scoreboard #(T) scb_type;

//Section S3 : Register out_of_order_scoreboard into factory
`uvm_component_param_utils(scb_type)

//Section S4 : Define type_name of const static string type
const static string type_name= $sformatf("out_of_order_scoreboard #(%0s)",$typename(T));

//Section S5 : Define get_type_name method
virtual function string get_type_name();
return type_name;
endfunction

//Section S6: Define custom analysis ports to receive packet from iMon/oMonitor
`uvm_analysis_imp_decl(_inp)
`uvm_analysis_imp_decl(_outp)

//Section S7: Define analysis port to receive packet from iMonitor
uvm_analysis_imp_inp #(T,scb_type) mon_inp;
//Section S8: Define analysis port to receive packet from oMonitor
uvm_analysis_imp_outp #(T,scb_type) mon_outp;

//Section S9.1: Define queue q_inp to store packets from all monitors
T q_inp[$];

//Section S9.2: Define variables m_matches and m_mismatches
bit [31:0] m_matches,m_mismatches;

//Section S9.3: Define variables no_of_pkts_recvd to keep track of packet count
  bit[31:0] no_of_pkts_recvd;

//Section S10 : Define standard custom constructor
function new(string name="out_of_order_scoreboard",uvm_component parent);
	super.new(name,parent);
	`uvm_info(get_type_name(),"NEW scoreboard",UVM_NONE);
endfunction
//Section S11: Define build_phase to construct object for analysis ports
virtual function void build_phase(uvm_phase phase);
	super.build_phase(phase);

//Section S11.2 : Construct object for mon_inp analysis port
	mon_inp=new("mon_inp",this);
//Section S11.3 : Construct object for mon_outp analysis port
	mon_outp=new("mon_outp",this);
endfunction
//Section S12: Define write_inp to receive packets from iMonitor and store in q_inp
	virtual function void write_inp(T pkt);
		T pkt_in;
//Section S12.1: clone the received pkt 
		$cast(pkt_in,pkt.clone());
//Section S12.2: Store the cloned pkt_in 
		q_inp.push_back(pkt_in);

	endfunction
//Section S13: Define write_outp to receive packets from oMonitor and search and compare
	virtual function void write_outp(T recvd_pkt);
		T ref_pkt;
		int get_index[$];
		int index;
		bit done;
//Section S13.1: Keep track of the received pkt count
		no_of_pkts_recvd++;

//Section S13.2: Search for matching pkt in q_inp with addr as the search criteria
		get_index=q_inp.find_index() with (item.PADDR==recvd_pkt.PADDR);

//Section S13.3: Loop through all matched indices 
		foreach( get_index[i]) begin
			index=get_index[i];
	//Section S13.4: get the pkt object from q_inp 
			ref_pkt=q_inp[index];
	//Section S13.5: Compare recived pkt with the ref_pkt object from q_inp
			if(ref_pkt.PWDATA==recvd_pkt.PRDATA) begin
	   //Section S13.6: Increment the m_matches count if pkt matches
				m_matches++;
		//Section S13.7: Delete matched pkt from q_inp	
				q_inp.delete(index);
				`uvm_info("SCB_MATCH",$sformatf("Packet %0d Matched",no_of_pkts_recvd),UVM_NONE);
				done=1;
		//Section S13.8: Break the foreach loop as we have matching pkt	
				break;
			end   
	   //Section S13.9: Loop through untill all indices exhaust	in get_index
			else done=0;
		end
 //Section S13.10: Increment m_mismatches count as none of the pkt from q_inp matches
		if(!done) begin
			m_mismatches++;
          `uvm_error("SCB_NO_MATCH",$sformatf("***Matching Packet NOT Found for the pkt_id=%0d***",no_of_pkts_recvd));
			`uvm_info("SCB",$sformatf("Expected::%0s",ref_pkt.convert2string()),UVM_NONE);
			`uvm_info("SCB",$sformatf("Received::%0s",recvd_pkt.convert2string()),UVM_NONE);
			done=0;
		end
	endfunction
//Section S14 : Implement extract_phase to send m_matches/m_mismatches count to environment
	virtual function void extract_phase(uvm_phase phase);
//Section S14.1 : use uvm_config_db::set to send m_matches count to environment
		uvm_config_db #(int)::set(null,"uvm_test_top.env","matches",m_matches);
//Section S14.2 : use uvm_config_db::set to send m_mismatches count to environment
		uvm_config_db #(int)::set(null,"uvm_test_top.env","m_mismatches",m_mismatches);
	endfunction

//Section S15 : Define report_phase to print m_matches/m_mismatches count.
	function void report_phase (uvm_phase phase);
		`uvm_info("SCB",$sformatf("Scoreboard completed with matches=%0d mismatches=%0d",m_matches,m_mismatches),UVM_NONE);
	endfunction
endclass