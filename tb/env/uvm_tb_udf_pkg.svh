package uvm_tb_udf_pkg;

  //===================== CLOCK ===================================
  // Clock periods
  parameter int HALF_CLK = 1;  // CLK = 500 MHz
  parameter int HALF_DDR2_CK  = 2;  // CK  = 250 MHz

  // Clock relationship
  parameter int unsigned CK_PER_CLK = HALF_DDR2_CK/HALF_CLK;



  //=============== GLOBAL CONFIGUARATION==========================  
  // DDR2 mode-register encoding and actual burst length
  parameter int unsigned BURST_LEN = 8;         // 8 data beats per burst
  parameter bit [2:0]    BL_CODE = 3'b011;      // DDR2 encoding for BL=8
  parameter bit          BURST_TYPE = 1'b0;     // Sequential
  parameter bit [2:0]    CAS_LATENCY = 3'b100;  // CL=4
  parameter bit [2:0]    CAS_W_LATENCY = 3'b011; // CWL=3
  parameter bit [2:0]    ADDITIVE_LATENCY = 3'b100; // AL=4
  
  // Data and address widths
  parameter int unsigned DQ_WIDTH = 16;
  parameter int unsigned DQS_WIDTH = 2;
  parameter int unsigned DM_WIDTH = 2;
  parameter int unsigned ROW_ADDR_WIDTH = 13;
  parameter int unsigned COL_ADDR_WIDTH = 10;
  parameter int unsigned BANK_ADDR_WIDTH = 2;
  parameter int unsigned ADDR_WIDTH = 25;
  parameter int unsigned RANK_BITS  = 1;

  // FIFO configuration
  parameter int unsigned FIFO_DEPTH = 64;
  parameter int unsigned FIFO_DEPTH_LOG2 = 6;
  



    //================ TIMING REQUIREMENTS =============================
  // DDR2 timing requirements in CK cycles
  parameter int unsigned T_RCD_CK_CYCLES  = 2;
  parameter int unsigned T_RP_CK_CYCLES   = 2;
  parameter int unsigned T_RAS_CK_CYCLES  = 10;
  parameter int unsigned T_RC_CK_CYCLES   = 12;
  parameter int unsigned T_RFC_CK_CYCLES  = 50;
  parameter int unsigned T_MRD_CK_CYCLES  = 2;
  parameter int unsigned T_WR_CK_CYCLES   = 4;
  parameter int unsigned T_RTP_CK_CYCLES  = 2;
  parameter int unsigned T_WTR_CK_CYCLES  = 2;
  parameter int unsigned T_RTW_CK_CYCLES  = 4;
  parameter int unsigned T_FAW_CK_CYCLES  = 20;
  parameter int unsigned T_XSR_CK_CYCLES  = 50;
  parameter int unsigned T_DLLK_CK_CYCLES = 200;

  // 200 us power-up wait:
  // 200 us / 4 ns per CK cycle = 50,000 CK cycles
  parameter int unsigned T_INIT_CK_CYCLES = 50_000;

  // Convert timing counts from DDR2 CK cycles to CLK cycles
  parameter int unsigned T_RCD_CLK_CYCLES  = T_RCD_CK_CYCLES  * CK_PER_CLK;
  parameter int unsigned T_RP_CLK_CYCLES   = T_RP_CK_CYCLES   * CK_PER_CLK;
  parameter int unsigned T_RAS_CLK_CYCLES  = T_RAS_CK_CYCLES  * CK_PER_CLK;
  parameter int unsigned T_RC_CLK_CYCLES   = T_RC_CK_CYCLES   * CK_PER_CLK;
  parameter int unsigned T_RFC_CLK_CYCLES  = T_RFC_CK_CYCLES  * CK_PER_CLK;
  parameter int unsigned T_MRD_CLK_CYCLES  = T_MRD_CK_CYCLES  * CK_PER_CLK;
  parameter int unsigned T_WR_CLK_CYCLES   = T_WR_CK_CYCLES   * CK_PER_CLK;
  parameter int unsigned T_RTP_CLK_CYCLES  = T_RTP_CK_CYCLES  * CK_PER_CLK;
  parameter int unsigned T_WTR_CLK_CYCLES  = T_WTR_CK_CYCLES  * CK_PER_CLK;
  parameter int unsigned T_RTW_CLK_CYCLES  = T_RTW_CK_CYCLES  * CK_PER_CLK;
  parameter int unsigned T_FAW_CLK_CYCLES  = T_FAW_CK_CYCLES  * CK_PER_CLK;
  parameter int unsigned T_XSR_CLK_CYCLES  = T_XSR_CK_CYCLES  * CK_PER_CLK;
  parameter int unsigned T_DLLK_CLK_CYCLES = T_DLLK_CK_CYCLES * CK_PER_CLK;
  parameter int unsigned T_INIT_CLK_CYCLES = T_INIT_CK_CYCLES * CK_PER_CLK;

  //================== HOST COMMAND =================================
  parameter bit [2:0] NOP = 3'b000;
  parameter bit [2:0] SCR = 3'b001;
  parameter bit [2:0] SCW = 3'b010;
  parameter bit [2:0] BLR = 3'b011;
  parameter bit [2:0] BLW = 3'b100;

endpackage