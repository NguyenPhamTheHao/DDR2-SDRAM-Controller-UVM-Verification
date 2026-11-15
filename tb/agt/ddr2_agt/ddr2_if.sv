`timescale 1ns/1ps
import uvm_tb_udf_pkg::*;
interface ddr2_if(input logic CLK, input logic RST);
    timeunit 1ns;
    timeprecision 1ps;

    //DDR2 Memory device interfaces
    logic [(1<<RANK_BITS)-1:0]   C0_CSBAR_PAD;
    logic         C0_RASBAR_PAD;
    logic         C0_CASBAR_PAD;
    logic         C0_WEBAR_PAD;
    logic [1:0]   C0_BA_PAD;
    logic [12:0]  C0_A_PAD;
    logic [1:0]   C0_DM_PAD;
    logic         C0_ODT_PAD;
    logic         C0_CK_PAD;
    logic         C0_CKBAR_PAD;
    logic         C0_CKE_PAD;
    logic [DATA_WIDTH-1:0]  C0_DQ_PAD;
    logic [1:0]   C0_DQS_PAD;
    logic [1:0]   C0_DQSBAR_PAD;

endinterface