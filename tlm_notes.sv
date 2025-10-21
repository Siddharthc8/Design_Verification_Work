UVM Ports
Port connects Implementation port
TLM (Transaction Level Modeling) ports(1.0)

1. TLM ports cannot be left open; they need to be connected using the connect method.
2. A port cannot be connected to multiple exports. It is always 1-1.

TLM 1.0 Interfaces(P ->producer,C->Consumer)
------------------
Interface                                              Purpose                           Method
---------------------------------------------
uvm_blocking_get_imp(P)           Blocking                                  get (output T tr) in producer 
uvm_blocking_get_port(C)

uvm_nonblocking_get_imp(P)       Nonblocking                    try_get  (output  T tr ) in  producer
uvm_nonblocking_get_port(C)

uvm_blocking_put_imp(C)               Blocking                                put (input  T tr) in consumer
uvm_blocking_put_port(P)
...
-------------------------------------------------------
Pull mode: Consumer  pulls the transaction (get)
Producer:
uvm_blocking_get_imp #(T)  send;
T tr;
task get (output  T tr);
tr= T::type_id::create("tr");
tr.randomize();
endtask
Consumer
uvm_blocking_get_port #(T)  recv;
T tr;
task run_phase (uvm_phase phase)
recv.get(tr);
drive(tr)
endtask



In agent: consumer. recv.connect(producer.send);

Push mode: Producer pushes the transaction (put).



Producer:

uvm_blocking_put_port #(T) send;


T tr;
task run_phase (uvm_phase phase)
tr= T::type_id::create("tr");
tr.randomize();
send.put(tr);
endtask
Consumer

uvm_blocking_put_imp #(T) recv;

T tr;
task put (input  T tr);
drive(tr);
endtask


In agent: producer.send.connect(consumer.recv);

Writing all the TLM ports  and imp ports in components(seqr,drvr) and connecting them in agent makes the code messy,

So,UVM has included the following definitions :
sequencer–driver communication is pull mode by default.
Ensures driver only gets items when it is ready to drive DUT signals.
Provides flow control — prevents overloading the DUT with transactions.
uvm_sequencer #(REQ=uvm_sequence_item, RSP=REQ) extends uvm_component;
  // Pull interface for the driver to get items
  uvm_seq_item_pull_imp #(REQ, RSP, uvm_sequencer #(REQ,RSP)) seq_item_export;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    seq_item_export = uvm_seq_item_pull_imp #(REQ, RSP, uvm_sequencer      #(REQ,RSP))::type_id::create("seq_item_export", this);
  endfunction
endclass
This  uvm_seq_item_pull_imp implements all the methods get_next_item,item_done,try_get,get,


3.class uvm_driver #(REQ=uvm_sequence_item, RSP=REQ) extends uvm_component;
  // Pull port to get transactions from sequencer
  uvm_seq_item_pull_port #(REQ, RSP) seq_item_port;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    // Create the pull port instance
    seq_item_port = uvm_seq_item_pull_port #(REQ, RSP)::type_id::create("seq_item_port", this);
  endfunction
  // The main run_phase
  virtual task run_phase(uvm_phase phase);
    REQ tr;
    forever begin
      // Pull transaction from sequencer
      seq_item_port.get_next_item(tr);
      `uvm_info("DRV", $sformatf("Got transaction: %s", tr.convert2string()), UVM_MEDIUM)
      // Drive DUT signals here
      drive(tr);
      // Notify sequencer that driver is done
      seq_item_port.item_done();
    end
  endtask
endclass



TLM FIFO(FIFO has all the imp ports)

Queue with blocking/unblocking get/put methods.


Channel between producer & consumer.

Producer pushes data to FIFO, consumer pulls from FIFO.
Uvm_seq_item -<>

Producer
             <>_ put_port put_port           
FIFO
<>put_imp put_export
<>_get_imp get_export
Consumer
<>_get_port get_port


Example in agent
uvm_tlm_fifo #(packet) fifo;Producer p;consumer c;
p.put_port.connect(fifo.put_export);
c.get_port.connect(fifo.get_export);

Note :Convention -export is used as handle for imp ports 


Analysis ports: no handshake  mechanism (non-blocking).

1. Can be left open; ports need not be connected.
2. One analysis port can connect to multiple analysis imp ports (1-many).

In monitor:
uvm_analysis_port #(T) ap;

In scoreboard:
uvm_analysis_imp #(T, scb) ap_imp;


Function void write(T tr);
..
endfunction

___________________________________________________________
The following doesn’t have readability
agent.mon.ap.connect(scb.ap_imp);

Pass-through ports :
In agent :  uvm_analysis_port #(T)  pass_ap
mon.ap.connect(this.pass_ap)
In env.
agent.pass_ap.connect(scb.ap_imp);
__________________________________________________

Analysis FIFO: Stores all the transactions so consumers can get() them later.

Example:
Mon:
uvm_analysis_port #(packet) ap;
Scb:
uvm_tlm_analysis_fifo #(packet) fifo;

In run_phase:
 forever begin 
fifo.get(pkt);
End

Env: mon.ap.connect(scb.fifo.analysis_export)

------------------------------------------------------
//Scoreboard

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

    



