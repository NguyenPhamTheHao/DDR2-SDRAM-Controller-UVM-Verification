class host_base_seq extends uvm_sequence #(host_tlm);
    `uvm_object_utils(host_base_seq)

    string my_name;

    function new(string name = "host_base_seq");
        super.new(name);
        my_name = name;
    endfunction

    // Submit one host cycle/transaction to the sequencer and driver.
    virtual task send_item(host_tlm req);
        start_item(req);
        finish_item(req);
    endtask

    // Create an inactive host cycle. The driver is expected to copy sampled
    // DUT outputs (READY, NOTFULL, VALIDOUT, DOUT, etc.) back into req before
    // item_done(), so sequences can inspect the returned fields.
    virtual task idle_cycle(output host_tlm req);
        req = host_tlm::type_id::create("idle_req");
        req.to_reset     = 1'b0;
        req.INITDDR      = 1'b0;
        req.cmd_put      = 1'b0;
        req.put_dataFIFO = 1'b0;
        req.CMD          = NOP;
        req.SZ           = 2'b00;
        req.ADDR         = '0;
        req.DIN          = '0;
        req.FETCHING     = 1'b0;
        send_item(req);
    endtask

    //================= RESET ========================================
    virtual task system_rst(input int unsigned reset_cycles = 2);
        host_tlm req;

        repeat (reset_cycles) begin
            req = host_tlm::type_id::create("reset_req");
            req.to_reset     = 1'b1;
            req.INITDDR      = 1'b0;
            req.cmd_put      = 1'b0;
            req.put_dataFIFO = 1'b0;
            req.CMD          = NOP;
            req.SZ           = 2'b00;
            req.ADDR         = '0;
            req.DIN          = '0;
            req.FETCHING     = 1'b0;
            send_item(req);
        end

        req = host_tlm::type_id::create("reset_release_req");
        req.to_reset     = 1'b0;
        req.INITDDR      = 1'b0;
        req.cmd_put      = 1'b0;
        req.put_dataFIFO = 1'b0;
        req.CMD          = NOP;
        req.SZ           = 2'b00;
        req.ADDR         = '0;
        req.DIN          = '0;
        req.FETCHING     = 1'b0;
        send_item(req);
    endtask

    //================= INITIALIZATION ===============================
    virtual task initialize_ddr(input int unsigned timeout_cycles = 200_000);
        host_tlm req;
        bit ready_seen;

        req = host_tlm::type_id::create("init_req");
        req.to_reset     = 1'b0;
        req.INITDDR      = 1'b1;
        req.cmd_put      = 1'b0;
        req.put_dataFIFO = 1'b0;
        req.CMD          = NOP;
        req.SZ           = 2'b00;
        req.ADDR         = '0;
        req.DIN          = '0;
        req.FETCHING     = 1'b0;
        send_item(req);

        ready_seen = req.READY;
        for (int unsigned cycle = 0; (cycle < timeout_cycles) && !ready_seen; cycle++) begin
            idle_cycle(req);
            ready_seen = req.READY;
        end

        if (!ready_seen)
            `uvm_fatal("HOST_INIT_TIMEOUT", $sformatf("READY was not asserted within %0d host cycles", timeout_cycles))
    endtask

    // Wait for command FIFO space. The driver returns current NOTFULL in req.
    virtual task wait_command_space(input int unsigned timeout_cycles = 10_000);
        host_tlm req;
        bit space_seen;

        space_seen = 1'b0;
        for (int unsigned cycle = 0; (cycle < timeout_cycles) && !space_seen; cycle++) begin
            idle_cycle(req);
            space_seen = req.NOTFULL;
        end

        if (!space_seen)
            `uvm_fatal("HOST_CMD_FIFO_TIMEOUT", $sformatf("NOTFULL was not asserted within %0d host cycles", timeout_cycles))
    endtask

    virtual task send_command(input bit [2:0] cmd,
                              input bit [ADDR_WIDTH-1:0] addr,
                              input bit [1:0] sz = 2'b00);
        host_tlm req;

        wait_command_space();
        req = host_tlm::type_id::create("cmd_req");
        req.to_reset     = 1'b0;
        req.INITDDR      = 1'b0;
        req.cmd_put      = 1'b1;
        req.put_dataFIFO = 1'b0;
        req.CMD          = cmd;
        req.SZ           = sz;
        req.ADDR         = addr;
        req.DIN          = '0;
        req.FETCHING     = 1'b0;
        send_item(req);
    endtask

    virtual task send_write_word(input bit [DATA_WIDTH-1:0] data_word);
        host_tlm req;

        req = host_tlm::type_id::create("write_data_req");
        req.to_reset     = 1'b0;
        req.INITDDR      = 1'b0;
        req.cmd_put      = 1'b0;
        req.put_dataFIFO = 1'b1;
        req.CMD          = NOP;
        req.SZ           = 2'b00;
        req.ADDR         = '0;
        req.DIN          = data_word;
        req.FETCHING     = 1'b0;
        send_item(req);
    endtask

    // SCW uses one BL=8 physical burst in the current protocol engine.
    virtual task scalar_write(input bit [ADDR_WIDTH-1:0] addr,
                              input bit [DATA_WIDTH-1:0] data [0:BURST_LEN-1]);
        send_command(SCW, addr, 2'b00);
        foreach (data[i])
            send_write_word(data[i]);
    endtask

    // Fetch one returned word. Timeout is in host item cycles.
    virtual task fetch_word(output bit [DATA_WIDTH-1:0] data_word,
                            output bit [ADDR_WIDTH-1:0] data_addr,
                            input int unsigned timeout_cycles = 10_000);
        host_tlm req;
        bit valid_seen;

        valid_seen = 1'b0;
        data_word  = '0;
        data_addr  = '0;

        for (int unsigned cycle = 0; (cycle < timeout_cycles) && !valid_seen; cycle++) begin
            req = host_tlm::type_id::create("fetch_req");
            req.to_reset     = 1'b0;
            req.INITDDR      = 1'b0;
            req.cmd_put      = 1'b0;
            req.put_dataFIFO = 1'b0;
            req.CMD          = NOP;
            req.SZ           = 2'b00;
            req.ADDR         = '0;
            req.DIN          = '0;
            req.FETCHING     = 1'b1;
            send_item(req);

            valid_seen = req.VALIDOUT;
            if (valid_seen) begin
                data_word = req.DOUT;
                data_addr = req.RADDR;
            end
        end

        if (!valid_seen)
            `uvm_fatal("HOST_READ_TIMEOUT", $sformatf("No valid read data within %0d host cycles", timeout_cycles))
    endtask

    // SCR returns one BL=8 burst in the current protocol implementation.
    // Return the first word and drain the remaining beats to avoid FIFO buildup.
    virtual task scalar_read(input bit [ADDR_WIDTH-1:0] addr,
                             output bit [DATA_WIDTH-1:0] data_word);
        bit [DATA_WIDTH-1:0] beat;
        bit [ADDR_WIDTH-1:0] beat_addr;

        send_command(SCR, addr, 2'b00);
        fetch_word(data_word, beat_addr);
        repeat (BURST_LEN - 1)
            fetch_word(beat, beat_addr);
    endtask

    virtual task block_write(input bit [ADDR_WIDTH-1:0] addr,
                             input bit [1:0] size,
                             input bit [DATA_WIDTH-1:0] data[]);
        int unsigned expected_beats;

        expected_beats = (int'(size) + 1) * BURST_LEN;
        if (data.size() != expected_beats)
            `uvm_fatal("HOST_BLW_SIZE", $sformatf("SZ=%0d requires %0d data words, received %0d", size, expected_beats, data.size()))

        send_command(BLW, addr, size);
        foreach (data[i])
            send_write_word(data[i]);
    endtask

    virtual task block_read(input bit [ADDR_WIDTH-1:0] addr,
                            input bit [1:0] size,
                            output bit [DATA_WIDTH-1:0] data[]);
        int unsigned expected_beats;
        bit [ADDR_WIDTH-1:0] beat_addr;

        expected_beats = (int'(size) + 1) * BURST_LEN;
        data = new[expected_beats];

        send_command(BLR, addr, size);
        foreach (data[i])
            fetch_word(data[i], beat_addr);
    endtask

endclass
