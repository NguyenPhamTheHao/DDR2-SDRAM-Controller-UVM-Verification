import uvm_tb_udf_pkg::*;
interface global_if (output logic CLK, output logic RST);
// pragma attribute CLK_RST_if partition_interface_xif

    //
    // Generate reset
    //
    task do_reset (integer reset_length); // pragma tbx xtf
        RST = 1;
        #(reset_length*HALF_CLK*2);
        RST = 0;
    endtask
    //
    // Generate clock
    //
    initial begin
        #1;
        CLK = 1;
        forever begin
            #HALF_CLK CLK = ~CLK;
        end
    end

endinterface