`include "axi_env_pkg.sv"
program axi_program(axi_if pif);

import uvm_pkg::*;
import axi_env_pkg::*;
`include "base_test.sv"

initial begin
 $timeformat(-9,1,"ns",10);
 uvm_config_db #(virtual axi_if)::set(null,"uvm_test_top","master_if",pif);
 run_test();
end

endprogram
