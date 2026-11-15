`timescale 1ns/1ps
import uvm_tb_udf_pkg::*;
interface host_if (input logic CLK, input logic RST);
    timeunit 1ns;
    timeprecision 1ps;
    
    // External signal from Master
    logic         INITDDR;
    logic [2:0]   CMD;
    logic [1:0]   SZ;
    logic [ADDR_WIDTH-1:0]  ADDR;
    logic [DATA_WIDTH-1:0]  DIN;
    logic         FETCHING;
    logic [DATA_WIDTH-1:0]  DOUT;
    logic [ADDR_WIDTH-1:0]  RADDR;
    logic [FIFO_DEPTH_LOG2:0]   FILLCOUNT;
    logic         READY;
    logic         VALIDOUT;
    logic         NOTFULL;

    //Optional interface
    logic         SELFREF_REQ;
    logic         SELFREF_EXIT;
    logic         PWRDOWN_REQ;
    logic         PWRDOWN_EXIT;
    logic [RANK_BITS-1:0]   RANK_SEL;
    logic         cmd_put; 
    logic         put_dataFIFO;
    logic         DLL_REQ;
    logic         DLL_MODE;
    logic         DLL_BUSY;
    logic         SELFREF_ACTIVE;
    logic         PWRDOWN_ACTIVE;
endinterface