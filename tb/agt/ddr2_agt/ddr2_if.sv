`timescale 1ns/1ps
import uvm_tb_udf_pkg::*;
interface ddr2_if(input logic CLK, input logic RST);
    timeunit 1ns;
    timeprecision 1ps;

    // DDR2 command/address inputs observed from the controller.
    logic [(1<<RANK_BITS)-1:0] C0_CSBAR_PAD;
    logic                     C0_RASBAR_PAD;
    logic                     C0_CASBAR_PAD;
    logic                     C0_WEBAR_PAD;
    logic [1:0]               C0_BA_PAD;
    logic [12:0]              C0_A_PAD;
    logic [1:0]               C0_DM_PAD;
    logic                     C0_ODT_PAD;
    logic                     C0_CK_PAD;
    logic                     C0_CKBAR_PAD;
    logic                     C0_CKE_PAD;

    // DDR2 data/strobe pins are true bidirectional nets. The DUT drives them
    // during WRITE; the verification memory model drives them during READ.
    tri [DATA_WIDTH-1:0] C0_DQ_PAD;
    tri [1:0]            C0_DQS_PAD;
    tri [1:0]            C0_DQSBAR_PAD;

    // Device-model drive side. The driver releases these enables except while
    // returning a READ burst, allowing the controller to own the bus on WRITE.
    logic [DATA_WIDTH-1:0] mem_dq_data;
    logic [1:0]            mem_dqs_data;
    logic [1:0]            mem_dqsbar_data;
    logic                  mem_dq_oe;
    logic                  mem_dqs_oe;
    logic                  mem_dqsbar_oe;

    assign C0_DQ_PAD     = mem_dq_oe     ? mem_dq_data     : {DATA_WIDTH{1'bz}};
    assign C0_DQS_PAD    = mem_dqs_oe    ? mem_dqs_data    : 2'bzz;
    assign C0_DQSBAR_PAD = mem_dqsbar_oe ? mem_dqsbar_data : 2'bzz;

    initial begin
        mem_dq_data     = '0;
        mem_dqs_data    = '0;
        mem_dqsbar_data = '1;
        mem_dq_oe       = 1'b0;
        mem_dqs_oe      = 1'b0;
        mem_dqsbar_oe   = 1'b0;
    end
endinterface
