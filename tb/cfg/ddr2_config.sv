// Verification-side configuration for the DDR2 model.
// Timing values below are copied from the project specification / DDR2.md.
// All defaults come from uvm_tb_udf_pkg. CK timing fields are in DDR2 CK
// cycles; CLK timing fields are in controller CLK cycles.
class ddr2_config extends uvm_object;
    `uvm_object_utils(ddr2_config)

    // Clock relationship from the design specification.
    int unsigned clk_mhz = CLK_MHZ;
    int unsigned ck_mhz = DDR2_CK_MHZ;
    int unsigned ck_per_clk = CK_PER_CLK;

    // Device geometry and data path from the specification.
    int unsigned data_width = DATA_WIDTH;
    int unsigned dqs_width = DQS_WIDTH;
    int unsigned dm_width = DM_WIDTH;
    int unsigned bank_count = DDR2_BANK_COUNT;
    int unsigned row_count = DDR2_ROW_COUNT;
    int unsigned column_count = DDR2_COLUMN_COUNT;
    int unsigned rank_count = DDR2_RANK_COUNT;
    int unsigned model_mem_depth = DDR2_MODEL_MEM_DEPTH;

    // Mode-register configuration, stored as decoded values.
    int unsigned burst_len = BURST_LEN;
    int unsigned cas_latency = int'(CAS_LATENCY);
    int unsigned additive_latency = int'(ADDITIVE_LATENCY);
    int unsigned cas_write_latency = int'(CAS_W_LATENCY);
    bit          sequential_burst = (BURST_TYPE == 1'b0);

    // Address-pin convention used by the supplied ddr2_simple_mem.v.
    // 1: A[0] is AP and A[9:1] is the column (legacy reference-model map).
    // 0: A[10] is AP and A[9:0] is the column (DDR2 pin convention in the PDF).
    bit legacy_simple_mem_address_map = 1'b1;

    // Timing requirements in CK cycles. Turnaround values below represent
    // direct command-to-command spacing for BL=8, CL=4.
    int unsigned t_rcd_ck_cycles  = T_RCD_CK_CYCLES;
    int unsigned t_rp_ck_cycles   = T_RP_CK_CYCLES;
    int unsigned t_ras_ck_cycles  = T_RAS_CK_CYCLES;
    int unsigned t_rc_ck_cycles   = T_RC_CK_CYCLES;
    int unsigned t_rfc_ck_cycles  = T_RFC_CK_CYCLES;
    int unsigned t_mrd_ck_cycles  = T_MRD_CK_CYCLES;
    int unsigned t_wr_ck_cycles   = T_WR_CK_CYCLES;
    int unsigned t_rtp_ck_cycles  = T_RTP_CK_CYCLES;
    int unsigned t_wtr_ck_cycles  = T_WTR_CK_CYCLES; // WRITE command -> READ command
    int unsigned t_rtw_ck_cycles  = T_RTW_CK_CYCLES; // READ command -> WRITE command
    int unsigned t_faw_ck_cycles  = T_FAW_CK_CYCLES;
    int unsigned t_xsr_ck_cycles  = T_XSR_CK_CYCLES;
    int unsigned t_dllk_ck_cycles = T_DLLK_CK_CYCLES;

    // Controller-clock values explicitly documented in DDR2.md / timing config.
    int unsigned t_init_clk_cycles = T_INIT_CLK_CYCLES;
    int unsigned refresh_trigger_clk_cycles = REFRESH_TRIGGER_CLK_CYCLES;
    int unsigned refresh_max_interval_clk_cycles = REFRESH_MAX_INTERVAL_CLK_CYCLES;
    int unsigned t_rrd_clk_cycles = T_RRD_CLK_CYCLES;

    bit check_timing = 1'b1;

    function new(string name = "ddr2_config");
        super.new(name);
    endfunction

    function automatic int unsigned read_latency_ck_cycles();
        return additive_latency + cas_latency;
    endfunction

    function automatic int unsigned write_latency_ck_cycles();
        return additive_latency + cas_write_latency;
    endfunction

    function automatic int unsigned ck_to_clk(input int unsigned ck_cycles);
        return ck_cycles * ck_per_clk;
    endfunction

    function automatic int unsigned t_rcd_clk_cycles(); return ck_to_clk(t_rcd_ck_cycles); endfunction
    function automatic int unsigned t_rp_clk_cycles();  return ck_to_clk(t_rp_ck_cycles);  endfunction
    function automatic int unsigned t_ras_clk_cycles(); return ck_to_clk(t_ras_ck_cycles); endfunction
    function automatic int unsigned t_rc_clk_cycles();  return ck_to_clk(t_rc_ck_cycles);  endfunction
    function automatic int unsigned t_rfc_clk_cycles(); return ck_to_clk(t_rfc_ck_cycles); endfunction
    function automatic int unsigned t_mrd_clk_cycles(); return ck_to_clk(t_mrd_ck_cycles); endfunction
    function automatic int unsigned t_wr_clk_cycles();  return ck_to_clk(t_wr_ck_cycles);  endfunction
    function automatic int unsigned t_rtp_clk_cycles(); return ck_to_clk(t_rtp_ck_cycles); endfunction
    function automatic int unsigned t_wtr_clk_cycles(); return ck_to_clk(t_wtr_ck_cycles); endfunction
    function automatic int unsigned t_rtw_clk_cycles(); return ck_to_clk(t_rtw_ck_cycles); endfunction
    function automatic int unsigned t_faw_clk_cycles(); return ck_to_clk(t_faw_ck_cycles); endfunction
    function automatic int unsigned t_xsr_clk_cycles(); return ck_to_clk(t_xsr_ck_cycles); endfunction
    function automatic int unsigned t_dllk_clk_cycles();return ck_to_clk(t_dllk_ck_cycles);endfunction

    function automatic bit is_valid();
        if (clk_mhz != CLK_MHZ || ck_mhz != DDR2_CK_MHZ || ck_per_clk != CK_PER_CLK) return 1'b0;
        if (data_width != DATA_WIDTH || dqs_width != DQS_WIDTH || dm_width != DM_WIDTH) return 1'b0;
        if (bank_count != DDR2_BANK_COUNT || row_count != DDR2_ROW_COUNT ||
            column_count != DDR2_COLUMN_COUNT || rank_count != DDR2_RANK_COUNT) return 1'b0;
        if (burst_len != BURST_LEN || cas_latency != int'(CAS_LATENCY) ||
            additive_latency != int'(ADDITIVE_LATENCY) ||
            cas_write_latency != int'(CAS_W_LATENCY) ||
            sequential_burst != (BURST_TYPE == 1'b0)) return 1'b0;
        // The driver memory array has a compile-time size, so config must match it.
        if (model_mem_depth != DDR2_MODEL_MEM_DEPTH || model_mem_depth == 0 ||
            (model_mem_depth & (model_mem_depth - 1)) != 0) return 1'b0;
        if (t_rcd_ck_cycles != T_RCD_CK_CYCLES || t_rp_ck_cycles != T_RP_CK_CYCLES ||
            t_ras_ck_cycles != T_RAS_CK_CYCLES) return 1'b0;
        if (t_rc_ck_cycles != T_RC_CK_CYCLES || t_rfc_ck_cycles != T_RFC_CK_CYCLES ||
            t_mrd_ck_cycles != T_MRD_CK_CYCLES) return 1'b0;
        if (t_wr_ck_cycles != T_WR_CK_CYCLES || t_rtp_ck_cycles != T_RTP_CK_CYCLES ||
            t_wtr_ck_cycles != T_WTR_CK_CYCLES) return 1'b0;
        if (t_rtw_ck_cycles != T_RTW_CK_CYCLES || t_faw_ck_cycles != T_FAW_CK_CYCLES ||
            t_xsr_ck_cycles != T_XSR_CK_CYCLES) return 1'b0;
        if (t_dllk_ck_cycles != T_DLLK_CK_CYCLES || t_init_clk_cycles != T_INIT_CLK_CYCLES) return 1'b0;
        if (refresh_trigger_clk_cycles != REFRESH_TRIGGER_CLK_CYCLES ||
            refresh_max_interval_clk_cycles != REFRESH_MAX_INTERVAL_CLK_CYCLES ||
            t_rrd_clk_cycles != T_RRD_CLK_CYCLES) return 1'b0;
        return 1'b1;
    endfunction
endclass
