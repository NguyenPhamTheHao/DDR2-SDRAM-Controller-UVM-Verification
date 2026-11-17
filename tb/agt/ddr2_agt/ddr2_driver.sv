// Reactive verification-side DDR2 device model.
// It observes command/address pins, tracks bank state and timing, stores writes,
// and returns read bursts over the bidirectional DQ/DQS interface.
class ddr2_driver extends uvm_component;
    `uvm_component_utils(ddr2_driver)

    virtual ddr2_if vif;
    ddr2_config cfg;

    localparam int RANK_COUNT = DDR2_RANK_COUNT;
    localparam int BANK_COUNT = DDR2_BANK_COUNT;
    localparam int MODEL_MEM_DEPTH = DDR2_MODEL_MEM_DEPTH;
    localparam int FAW_WINDOW_SIZE = 4;

    bit [DATA_WIDTH-1:0] mem [0:RANK_COUNT-1][0:MODEL_MEM_DEPTH-1];
    bit                 bank_open [0:RANK_COUNT-1][0:BANK_COUNT-1];
    bit [ROW_ADDR_WIDTH-1:0] open_row [0:RANK_COUNT-1][0:BANK_COUNT-1];
    int unsigned last_act_ck [0:RANK_COUNT-1][0:BANK_COUNT-1];
    int unsigned last_pre_ck [0:RANK_COUNT-1][0:BANK_COUNT-1];
    int unsigned last_read_ck [0:RANK_COUNT-1][0:BANK_COUNT-1];
    int unsigned last_write_ck [0:RANK_COUNT-1][0:BANK_COUNT-1];
    bit has_act [0:RANK_COUNT-1][0:BANK_COUNT-1];
    bit has_pre [0:RANK_COUNT-1][0:BANK_COUNT-1];
    bit has_read [0:RANK_COUNT-1][0:BANK_COUNT-1];
    bit has_write [0:RANK_COUNT-1][0:BANK_COUNT-1];

    int unsigned ck_cycle;
    int unsigned core_clk_cycle;
    int unsigned cke_rise_core_clk;
    bit powerup_wait_checked;
    bit first_command_seen;
    int unsigned dll_reset_ck;
    bit has_dll_reset;
    int unsigned last_ref_ck;
    bit has_ref;
    int unsigned last_mrs_ck;
    bit has_mrs;
    int unsigned last_read_bus_ck;
    bit has_read_bus;
    int unsigned last_write_bus_ck;
    bit has_write_bus;
    int unsigned last_act_bus_ck;
    bit has_act_bus;
    int unsigned act_window [0:FAW_WINDOW_SIZE-1];
    int unsigned act_seen;
    int unsigned next_read_data_ck;
    bit has_read_schedule;
    int unsigned next_write_data_ck;
    bit has_write_schedule;
    int unsigned read_bursts_pending;
    int unsigned model_epoch;

    function new(string name = "ddr2_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ddr2_if)::get(this, "", "vif", vif))
            `uvm_fatal("DDR2_NO_VIF", "ddr2_if virtual interface was not configured for ddr2_driver")
        if (!uvm_config_db#(ddr2_config)::get(this, "", "cfg", cfg))
            cfg = ddr2_config::type_id::create("cfg");
        if (!cfg.is_valid())
            `uvm_fatal("DDR2_BAD_CFG", "ddr2_config contains values outside the project specification")
    endfunction

    task run_phase(uvm_phase phase);
        initialize_model();
        release_device_bus();
        fork
            command_monitor();
            controller_clock_monitor();
        join
    endtask

    task command_monitor();
        forever begin
            @(posedge vif.C0_CK_PAD);
            if (vif.RST === 1'b1) begin
                reset_protocol_state();
                release_device_bus();
            end else if (vif.C0_CKE_PAD === 1'b1) begin
                ck_cycle++;
                sample_command();
            end
        end
    endtask

    task controller_clock_monitor();
        forever begin
            @(posedge vif.CLK);
            if (vif.RST === 1'b1) begin
                core_clk_cycle = 0;
                cke_rise_core_clk = 0;
                powerup_wait_checked = 1'b0;
            end else begin
                core_clk_cycle++;
                if (!powerup_wait_checked && vif.C0_CKE_PAD === 1'b1) begin
                if (cfg.check_timing && core_clk_cycle < cfg.t_init_clk_cycles)
                        `uvm_fatal("DDR2_TINIT", $sformatf("CKE asserted after %0d CLK cycles; required %0d CLK cycles",
                                    core_clk_cycle, cfg.t_init_clk_cycles))
                    cke_rise_core_clk = core_clk_cycle;
                    powerup_wait_checked = 1'b1;
                end
            end
        end
    endtask

    function void initialize_model();
        int r, b, i;
        ck_cycle = 0;
        core_clk_cycle = 0;
        cke_rise_core_clk = 0;
        powerup_wait_checked = 1'b0;
        first_command_seen = 1'b0;
        dll_reset_ck = 0;
        has_dll_reset = 1'b0;
        for (r = 0; r < RANK_COUNT; r++) begin
            for (i = 0; i < MODEL_MEM_DEPTH; i++) mem[r][i] = '0;
            for (b = 0; b < BANK_COUNT; b++) begin
                bank_open[r][b] = 1'b0;
                open_row[r][b] = '0;
                has_act[r][b] = 1'b0;
                has_pre[r][b] = 1'b0;
                has_read[r][b] = 1'b0;
                has_write[r][b] = 1'b0;
                last_act_ck[r][b] = 0;
                last_pre_ck[r][b] = 0;
                last_read_ck[r][b] = 0;
                last_write_ck[r][b] = 0;
            end
        end
        reset_protocol_state();
    endfunction

    function void reset_protocol_state();
        int r, b;
        ck_cycle = 0;
        last_ref_ck = 0;
        has_ref = 1'b0;
        last_mrs_ck = 0;
        has_mrs = 1'b0;
        last_read_bus_ck = 0;
        has_read_bus = 1'b0;
        last_write_bus_ck = 0;
        has_write_bus = 1'b0;
        last_act_bus_ck = 0;
        has_act_bus = 1'b0;
        first_command_seen = 1'b0;
        dll_reset_ck = 0;
        has_dll_reset = 1'b0;
        act_seen = 0;
        for (int i = 0; i < FAW_WINDOW_SIZE; i++) act_window[i] = 0;
        next_read_data_ck = 0;
        has_read_schedule = 1'b0;
        next_write_data_ck = 0;
        has_write_schedule = 1'b0;
        read_bursts_pending = 0;
        model_epoch++;
        for (r = 0; r < RANK_COUNT; r++) begin
            for (b = 0; b < BANK_COUNT; b++) begin
                bank_open[r][b] = 1'b0;
                has_act[r][b] = 1'b0;
                has_pre[r][b] = 1'b0;
                has_read[r][b] = 1'b0;
                has_write[r][b] = 1'b0;
            end
        end
    endfunction

    task release_device_bus();
        vif.mem_dq_oe = 1'b0;
        vif.mem_dqs_oe = 1'b0;
        vif.mem_dqsbar_oe = 1'b0;
        vif.mem_dq_data = '0;
        vif.mem_dqs_data = '0;
        vif.mem_dqsbar_data = '1;
    endtask

    function automatic int selected_rank();
        int r;
        selected_rank = -1;
        for (r = 0; r < RANK_COUNT; r++) begin
            if (vif.C0_CSBAR_PAD[r] === 1'b0) begin
                selected_rank = r;
                return selected_rank;
            end
        end
    endfunction

    function automatic int unsigned address_column();
        if (cfg.legacy_simple_mem_address_map)
            return {1'b0, vif.C0_A_PAD[9:1]};
        return vif.C0_A_PAD[9:0];
    endfunction

    function automatic bit address_auto_precharge();
        if (cfg.legacy_simple_mem_address_map) return vif.C0_A_PAD[0];
        return vif.C0_A_PAD[10];
    endfunction

    function automatic int unsigned memory_index(input int unsigned row,
                                                  input int unsigned bank,
                                                  input int unsigned col);
        int unsigned compact_addr;
        compact_addr = ((row & 'h1f) << 7) | ((bank & 2'b11) << 5) | (col & 'h1f);
        return compact_addr % cfg.model_mem_depth;
    endfunction

    task sample_command();
        int rank;
        int bank;
        int unsigned delta_clk;
        rank = selected_rank();
        if (rank < 0) return;
        bank = int'(vif.C0_BA_PAD);

        if (!(vif.C0_RASBAR_PAD === 1'b1 && vif.C0_CASBAR_PAD === 1'b1 && vif.C0_WEBAR_PAD === 1'b1)) begin
            if (!first_command_seen) begin
                delta_clk = core_clk_cycle - cke_rise_core_clk;
                if (cfg.check_timing && delta_clk < cfg.t_xsr_clk_cycles())
                    `uvm_fatal("DDR2_TXSR", $sformatf("First command after CKE at %0d CLK; tXSR requires %0d CLK",
                                delta_clk, cfg.t_xsr_clk_cycles()))
                first_command_seen = 1'b1;
            end
            if (has_mrs && !(vif.C0_RASBAR_PAD === 1'b0 && vif.C0_CASBAR_PAD === 1'b0 && vif.C0_WEBAR_PAD === 1'b0)) begin
                delta_clk = (ck_cycle - last_mrs_ck) * cfg.ck_per_clk;
                if (cfg.check_timing && delta_clk < cfg.t_mrd_clk_cycles())
                    `uvm_fatal("DDR2_TMRD", $sformatf("Command followed MRS after %0d CLK; tMRD requires %0d CLK",
                                delta_clk, cfg.t_mrd_clk_cycles()))
            end
            if (has_ref && !(vif.C0_RASBAR_PAD === 1'b0 && vif.C0_CASBAR_PAD === 1'b0 && vif.C0_WEBAR_PAD === 1'b1)) begin
                delta_clk = (ck_cycle - last_ref_ck) * cfg.ck_per_clk;
                if (cfg.check_timing && delta_clk < cfg.t_rfc_clk_cycles())
                    `uvm_fatal("DDR2_TRFC", $sformatf("Command issued %0d CLK after REFRESH; tRFC requires %0d CLK",
                                delta_clk, cfg.t_rfc_clk_cycles()))
            end
        end

        // DDR2 command decoding from CS#, RAS#, CAS#, and WE#.
        if (vif.C0_RASBAR_PAD === 1'b0 && vif.C0_CASBAR_PAD === 1'b1 && vif.C0_WEBAR_PAD === 1'b1)
            do_activate(rank, bank);
        else if (vif.C0_RASBAR_PAD === 1'b0 && vif.C0_CASBAR_PAD === 1'b1 && vif.C0_WEBAR_PAD === 1'b0)
            do_precharge(rank, bank);
        else if (vif.C0_RASBAR_PAD === 1'b0 && vif.C0_CASBAR_PAD === 1'b0 && vif.C0_WEBAR_PAD === 1'b1)
            do_refresh(rank);
        else if (vif.C0_RASBAR_PAD === 1'b0 && vif.C0_CASBAR_PAD === 1'b0 && vif.C0_WEBAR_PAD === 1'b0)
            do_mode_register_set(rank, bank);
        else if (vif.C0_RASBAR_PAD === 1'b1 && vif.C0_CASBAR_PAD === 1'b0 && vif.C0_WEBAR_PAD === 1'b1)
            do_read(rank, bank);
        else if (vif.C0_RASBAR_PAD === 1'b1 && vif.C0_CASBAR_PAD === 1'b0 && vif.C0_WEBAR_PAD === 1'b0)
            do_write(rank, bank);
    endtask

    task check_minimum(input bit condition, input string timing_name,
                       input int rank, input int bank, input int unsigned observed,
                       input int unsigned required_ck);
        if (cfg.check_timing && !condition)
            `uvm_fatal("DDR2_TIMING", $sformatf("%s violation at CK=%0d rank=%0d bank=%0d: observed %0d CK, required %0d CK",
                        timing_name, ck_cycle, rank, bank, observed, required_ck))
    endtask

    task do_activate(input int rank, input int bank);
        int unsigned delta;
        if (bank_open[rank][bank])
            `uvm_fatal("DDR2_BANK_ACTIVE", $sformatf("ACTIVATE to open bank %0d at CK=%0d", bank, ck_cycle))
        if (has_pre[rank][bank]) begin
            delta = ck_cycle - last_pre_ck[rank][bank];
            check_minimum(delta >= cfg.t_rp_ck_cycles, "tRP", rank, bank, delta, cfg.t_rp_ck_cycles);
        end
        if (has_act[rank][bank]) begin
            delta = ck_cycle - last_act_ck[rank][bank];
            check_minimum(delta >= cfg.t_rc_ck_cycles, "tRC", rank, bank, delta, cfg.t_rc_ck_cycles);
        end
        if (has_act_bus) begin
            // tRRD is supplied in controller CLK cycles by the timing config.
            delta = (ck_cycle - last_act_bus_ck) * cfg.ck_per_clk;
            check_minimum(delta >= cfg.t_rrd_clk_cycles, "tRRD", rank, bank, delta, cfg.t_rrd_clk_cycles);
        end
        if (act_seen >= FAW_WINDOW_SIZE - 1) begin
            delta = ck_cycle - act_window[0];
            check_minimum(delta >= cfg.t_faw_ck_cycles, "tFAW", rank, bank, delta, cfg.t_faw_ck_cycles);
        end
        for (int i = 0; i < FAW_WINDOW_SIZE - 1; i++) act_window[i] = act_window[i+1];
        act_window[FAW_WINDOW_SIZE-1] = ck_cycle;
        act_seen++;
        last_act_bus_ck = ck_cycle;
        has_act_bus = 1'b1;
        bank_open[rank][bank] = 1'b1;
        open_row[rank][bank] = vif.C0_A_PAD;
        last_act_ck[rank][bank] = ck_cycle;
        has_act[rank][bank] = 1'b1;
    endtask

    task do_precharge(input int rank, input int bank);
        int b;
        // A10 selects PRECHARGE ALL. The legacy A[0] mapping is only used for
        // READ/WRITE column/AP decoding in the supplied simple-memory model.
        if (vif.C0_A_PAD[10] === 1'b1) begin
            for (b = 0; b < BANK_COUNT; b++) check_precharge_bank(rank, b);
        end else begin
            check_precharge_bank(rank, bank);
        end
    endtask

    task check_precharge_bank(input int rank, input int bank);
        int unsigned delta;
        if (bank_open[rank][bank]) begin
            delta = ck_cycle - last_act_ck[rank][bank];
            check_minimum(delta >= cfg.t_ras_ck_cycles, "tRAS", rank, bank, delta, cfg.t_ras_ck_cycles);
        end
        if (has_read[rank][bank]) begin
            delta = ck_cycle - last_read_ck[rank][bank];
            check_minimum(delta >= cfg.t_rtp_ck_cycles, "tRTP", rank, bank, delta, cfg.t_rtp_ck_cycles);
        end
        if (has_write[rank][bank]) begin
            delta = ck_cycle - last_write_ck[rank][bank];
            // Conservatively include write latency and the complete BL=8 data window.
            check_minimum(delta >= cfg.write_latency_ck_cycles() + (cfg.burst_len / 2) + cfg.t_wr_ck_cycles,
                          "tWR", rank, bank, delta,
                          cfg.write_latency_ck_cycles() + (cfg.burst_len / 2) + cfg.t_wr_ck_cycles);
        end
        bank_open[rank][bank] = 1'b0;
        last_pre_ck[rank][bank] = ck_cycle;
        has_pre[rank][bank] = 1'b1;
    endtask

    task do_refresh(input int rank);
        int b;
        int unsigned delta;
        for (b = 0; b < BANK_COUNT; b++) begin
            if (bank_open[rank][b])
                `uvm_fatal("DDR2_REFRESH_ACTIVE", $sformatf("AUTO REFRESH while bank %0d is active", b))
            if (has_pre[rank][b]) begin
                delta = ck_cycle - last_pre_ck[rank][b];
                check_minimum(delta >= cfg.t_rp_ck_cycles, "tRP before REFRESH", rank, b,
                              delta, cfg.t_rp_ck_cycles);
            end
        end
        if (has_ref) begin
            delta = ck_cycle - last_ref_ck;
            check_minimum(delta >= cfg.t_rfc_ck_cycles, "tRFC", rank, -1, delta, cfg.t_rfc_ck_cycles);
            if (cfg.check_timing && delta > (cfg.refresh_max_interval_clk_cycles / cfg.ck_per_clk))
                `uvm_fatal("DDR2_TREFI", $sformatf("Refresh interval %0d CK exceeds configured maximum %0d CK",
                            delta, cfg.refresh_max_interval_clk_cycles / cfg.ck_per_clk))
        end
        last_ref_ck = ck_cycle;
        has_ref = 1'b1;
    endtask

    task do_mode_register_set(input int rank, input int bank);
        int unsigned delta;
        if (has_mrs) begin
            delta = ck_cycle - last_mrs_ck;
            check_minimum(delta >= cfg.t_mrd_ck_cycles, "tMRD", rank, bank, delta, cfg.t_mrd_ck_cycles);
        end
        last_mrs_ck = ck_cycle;
        has_mrs = 1'b1;
        if (bank == 0 && vif.C0_A_PAD[8] === 1'b1) begin
            dll_reset_ck = ck_cycle;
            has_dll_reset = 1'b1;
        end
    endtask

    task check_access(input int rank, input int bank, input bit is_write);
        int unsigned delta;
        if (!bank_open[rank][bank])
            `uvm_fatal("DDR2_BANK_CLOSED", $sformatf("READ/WRITE to closed bank %0d at CK=%0d", bank, ck_cycle))
        delta = ck_cycle - last_act_ck[rank][bank];
        check_minimum(delta >= cfg.t_rcd_ck_cycles, "tRCD", rank, bank, delta, cfg.t_rcd_ck_cycles);
        if (has_mrs) begin
            delta = ck_cycle - last_mrs_ck;
            check_minimum(delta >= cfg.t_mrd_ck_cycles, "tMRD", rank, bank, delta, cfg.t_mrd_ck_cycles);
        end
        // These are direct command-issue intervals, measured on CK, as defined
        // by the DDR2_SDRAM project profile for BL=8 and CL=4.
        if (is_write && has_read_bus) begin
            delta = ck_cycle - last_read_bus_ck;
            check_minimum(delta >= cfg.t_rtw_ck_cycles, "tRTW", rank, bank, delta, cfg.t_rtw_ck_cycles);
        end
        if (!is_write && has_write_bus) begin
            delta = ck_cycle - last_write_bus_ck;
            check_minimum(delta >= cfg.t_wtr_ck_cycles, "tWTR", rank, bank, delta, cfg.t_wtr_ck_cycles);
        end
        if (has_dll_reset) begin
            delta = ck_cycle - dll_reset_ck;
            check_minimum(delta >= cfg.t_dllk_ck_cycles, "tDLLK", rank, bank, delta, cfg.t_dllk_ck_cycles);
            has_dll_reset = 1'b0;
        end
    endtask

    task do_read(input int rank, input int bank);
        int unsigned col;
        int unsigned data_start_ck;
        bit ap;
        check_access(rank, bank, 1'b0);
        col = address_column();
        ap = address_auto_precharge();
        last_read_ck[rank][bank] = ck_cycle;
        has_read[rank][bank] = 1'b1;
        last_read_bus_ck = ck_cycle;
        has_read_bus = 1'b1;
        data_start_ck = ck_cycle + cfg.read_latency_ck_cycles();
        if (has_read_schedule && next_read_data_ck > data_start_ck)
            data_start_ck = next_read_data_ck;
        next_read_data_ck = data_start_ck + (cfg.burst_len / 2);
        has_read_schedule = 1'b1;
        read_bursts_pending++;
        fork
            drive_read_burst(rank, bank, open_row[rank][bank], col, ap, data_start_ck, model_epoch);
        join_none
    endtask

    task do_write(input int rank, input int bank);
        int unsigned col;
        int unsigned data_start_ck;
        bit ap;
        check_access(rank, bank, 1'b1);
        col = address_column();
        ap = address_auto_precharge();
        last_write_ck[rank][bank] = ck_cycle;
        has_write[rank][bank] = 1'b1;
        last_write_bus_ck = ck_cycle;
        has_write_bus = 1'b1;
        data_start_ck = ck_cycle + cfg.write_latency_ck_cycles();
        if (has_write_schedule && next_write_data_ck > data_start_ck)
            data_start_ck = next_write_data_ck;
        next_write_data_ck = data_start_ck + (cfg.burst_len / 2);
        has_write_schedule = 1'b1;
        fork
            capture_write_burst(rank, bank, open_row[rank][bank], col, ap, data_start_ck, model_epoch);
        join_none
    endtask

    task drive_read_burst(input int rank, input int bank, input int unsigned row,
                          input int unsigned col, input bit ap,
                          input int unsigned data_start_ck, input int unsigned epoch);
        int beat;
        int unsigned idx;
        while (ck_cycle + 1 < data_start_ck) @(posedge vif.C0_CK_PAD);
        for (beat = 0; beat < cfg.burst_len; beat++) begin
            if (epoch != model_epoch) return;
            // Set DQ while the strobe is stable, then toggle DQS on each CK edge.
            @(negedge vif.CLK);
            idx = memory_index(row, bank, col + beat);
            vif.mem_dq_data = mem[rank][idx];
            vif.mem_dq_oe = 1'b1;
            vif.mem_dqs_oe = 1'b1;
            vif.mem_dqsbar_oe = 1'b1;
            if (beat == 0 || (beat % 2) == 0) @(posedge vif.C0_CK_PAD);
            else                              @(negedge vif.C0_CK_PAD);
            if (epoch != model_epoch) return;
            vif.mem_dqs_data = ~vif.mem_dqs_data;
            vif.mem_dqsbar_data = ~vif.mem_dqsbar_data;
        end
        if (read_bursts_pending != 0) read_bursts_pending--;
        if (read_bursts_pending == 0) begin
            @(negedge vif.CLK);
            if (epoch == model_epoch) release_device_bus();
        end
        if (ap) begin
            repeat (cfg.t_rtp_ck_cycles()) @(posedge vif.C0_CK_PAD);
            if (epoch != model_epoch) return;
            bank_open[rank][bank] = 1'b0;
            last_pre_ck[rank][bank] = ck_cycle;
            has_pre[rank][bank] = 1'b1;
        end
    endtask

    task capture_write_burst(input int rank, input int bank, input int unsigned row,
                             input int unsigned col, input bit ap,
                             input int unsigned data_start_ck, input int unsigned epoch);
        int beat;
        int unsigned idx;
        bit [DATA_WIDTH-1:0] sampled_data;
        bit [DM_WIDTH-1:0] sampled_mask;
        bit [DATA_WIDTH-1:0] burst_data [0:BURST_LEN-1];
        bit [DM_WIDTH-1:0] burst_mask [0:BURST_LEN-1];
        while (ck_cycle < data_start_ck) @(posedge vif.C0_CK_PAD);
        for (beat = 0; beat < cfg.burst_len; beat++) begin
            @(posedge vif.C0_DQS_PAD[0] or negedge vif.C0_DQS_PAD[0]);
            if (epoch != model_epoch) return;
            sampled_data = vif.C0_DQ_PAD;
            sampled_mask = vif.C0_DM_PAD;
            burst_data[beat] = sampled_data;
            burst_mask[beat] = sampled_mask;
        end
        if (epoch != model_epoch) return;
        for (beat = 0; beat < cfg.burst_len; beat++) begin
            idx = memory_index(row, bank, col + beat);
            if (burst_mask[beat][0] === 1'b0) mem[rank][idx][7:0]  = burst_data[beat][7:0];
            if (burst_mask[beat][1] === 1'b0) mem[rank][idx][15:8] = burst_data[beat][15:8];
        end
        if (ap) begin
            repeat (cfg.t_wr_ck_cycles()) @(posedge vif.C0_CK_PAD);
            if (epoch != model_epoch) return;
            bank_open[rank][bank] = 1'b0;
            last_pre_ck[rank][bank] = ck_cycle;
            has_pre[rank][bank] = 1'b1;
        end
    endtask
endclass
