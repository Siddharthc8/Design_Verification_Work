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