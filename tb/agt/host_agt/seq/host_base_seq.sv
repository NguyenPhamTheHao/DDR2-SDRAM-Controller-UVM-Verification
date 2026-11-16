class host_base_seq extends uvm_sequence #(type REQ = uvm_sequence_item);
    `uvm_object_param_utils(host_base_seq #(REQ))

    string my_name;

    function new(string name = "host_base_seq");
        super.new(name);
        my_name = name;
    endfunction

    // Submit one host cycle/transaction to the sequencer and driver.
    virtual task send_item(REQ req);
        start_item(req);
        finish_item(req);
    endtask


    //=================================== RESET ========================================
    virtual task system_rst();
        REQ req;

        req = REQ::type_id::create("reset_req");
        req.to_reset = 1'b1;
        send_item(req);
    endtask

    virtual task idle_cycle(output REQ req);
        req = REQ::type_id::create("idle_req");
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


    //============================== INITIALIZATION =====================================
    virtual task initialize_ddr(input int unsigned timeout_cycles = 200_000);
        REQ req;
        bit ready_seen;

        req = REQ::type_id::create("init_req");
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


    //=============== SUPPORT CHECKING FIFO STATUS WHETHER EMPTY OR NOT===========================
    virtual task wait_command_space(input int unsigned timeout_cycles = 10_000);
        REQ req;
        bit space_seen;

        space_seen = 1'b0;
        for (int unsigned cycle = 0; (cycle < timeout_cycles) && !space_seen; cycle++) begin
            idle_cycle(req);
            space_seen = req.NOTFULL;
        end

        if (!space_seen)
            `uvm_fatal("HOST_CMD_FIFO_TIMEOUT", $sformatf("NOTFULL was not asserted within %0d host cycles", timeout_cycles))
    endtask


    //===================================== SEND COMMAND ===========================================
    virtual task send_command(input bit [2:0] cmd,
                              input bit [ADDR_WIDTH-1:0] addr,
                              input bit [1:0] sz = 2'b00);
        REQ req;

        wait_command_space();
        req = REQ::type_id::create("cmd_req");
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

    //==================================== SEND WRITE DATA ==========================================
    virtual task send_write_word(input bit [DATA_WIDTH-1:0] data_word);
        REQ req;

        req = REQ::type_id::create("write_data_req");
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
        REQ req;
        bit valid_seen;

        valid_seen = 1'b0;
        data_word  = '0;
        data_addr  = '0;

        for (int unsigned cycle = 0; (cycle < timeout_cycles) && !valid_seen; cycle++) begin
            req = REQ::type_id::create("fetch_req");
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
    
    // A scalar read returns one complete burst of BURST_LEN beats.
    virtual task scalar_read(input bit [ADDR_WIDTH-1:0] addr,
                             output bit [DATA_WIDTH-1:0] data [0:BURST_LEN-1]);
        bit [ADDR_WIDTH-1:0] beat_addr;

        send_command(SCR, addr, 2'b00);
        foreach (data[i])
            fetch_word(data[i], beat_addr);
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
