class out_of_order_scoreboard #(type T=transaction) extends uvm_scoreboard;

typedef out_of_order_scoreboard #(T) scb_type;

`uvm_component_param_utils(scb_type)

const static string type_name= $sformatf("out_of_order_scoreboard #(%0s)",$typename(T));

virtual function string get_type_name();
return type_name;
endfunction

`uvm_analysis_imp_decl(_inp)
`uvm_analysis_imp_decl(_outp)

uvm_analysis_imp_inp #(T,scb_type) mon_in;
uvm_analysis_imp_outp #(T,scb_type) mon_out;

//T q_inp[$]; might need in future

bit [31:0] m_matches,m_mismatches;
	T ref_pkt;


function new(string name="out_of_order_scoreboard",uvm_component parent);
	super.new(name,parent);
	`uvm_info(get_type_name(),"NEW scoreboard",UVM_NONE);
endfunction

virtual function void build_phase(uvm_phase phase);
	super.build_phase(phase);

	mon_in=new("mon_in",this);
	mon_out=new("mon_out",this);
endfunction
	
virtual function void write_inp(T pkt);
			$cast(ref_pkt,pkt.clone());
        //	`uvm_info("SCB_gargi",$sformatf("ADDR: %0p,Expected::%0p",pkt.awaddr_arr,pkt.wdata_arr),UVM_NONE);
	endfunction

	virtual function void write_outp(T recvd_pkt);
		
        bit addr_flag,data_flag,rresp_flag; 

            foreach(ref_pkt.awaddr_arr[i]) begin
                if(ref_pkt.awaddr_arr[i] !=recvd_pkt.araddr_arr[i] )  begin
                        `uvm_error("SCB_ADDR_MISMATCH",$sformatf("beat with expected addr %0h is mismatching  with recvd add %0h ",ref_pkt.awaddr_arr[i],recvd_pkt.araddr_arr[i]));
                        addr_flag=1;
                        break;
                end
                else addr_flag=0;  
            end

            foreach(ref_pkt.wdata_arr[i]) begin
                if(ref_pkt.wdata_arr[i] !=recvd_pkt.rdata_arr[i] )  begin
                        `uvm_error("SCB_DATA_MISMATCH",$sformatf("beat with expected data %0h is mismatching  with recvd data %0h ",ref_pkt.wdata_arr[i],recvd_pkt.rdata_arr[i]));
                        data_flag=1;
                        break;
                    end
                else data_flag=0;
            end

            foreach(recvd_pkt.rresp_arr[i]) begin
                    if(recvd_pkt.rresp_arr[i])  `uvm_error("SCB_RRESP",$sformatf("beat with addr %0h is erroneous ",recvd_pkt.araddr_arr[i]));
                    rresp_flag=1;
            end

			if(ref_pkt.bresp) `uvm_error("SCB_BRESP",$sformatf(" Write Transaction is erroneous "));
                                
            if(addr_flag || data_flag || ref_pkt.bresp || rresp_flag ) m_mismatches++;
            else   m_matches++;
	
	endfunction

	virtual function void extract_phase(uvm_phase phase);
      uvm_config_db #(int)::set(null,"uvm_test_top.env","matches",m_matches);
      uvm_config_db #(int)::set(null,"uvm_test_top.env","m_mismatches",m_mismatches);
	endfunction

	function void report_phase (uvm_phase phase);
		`uvm_info("SCB",$sformatf("Scoreboard completed with matches=%0d mismatches=%0d",m_matches,m_mismatches),UVM_NONE);
	endfunction
endclass

    



