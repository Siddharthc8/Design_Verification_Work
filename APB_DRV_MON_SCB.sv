
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




