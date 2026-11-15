class host_tlm extends uvm_sequence_item;
    string my_name;
    function new(string name = "host_tlm");
        super.new(name);
        my_name = name;
    endfunction

    //External objects of interface
    // Initialization is controlled explicitly by the initialization sequence,
    // not randomized with normal host memory transactions.
    bit  INITDDR;
    rand bit [2:0]  CMD;
    rand bit [1:0]  SZ;
    rand bit [ADDR_WIDTH-1:0]  ADDR;
    rand bit [DATA_WIDTH-1:0]  DIN;
    bit  FETCHING;
    bit [DATA_WIDTH-1:0]  DOUT;
    bit [ADDR_WIDTH-1:0]  RADDR;
    bit [FIFO_DEPTH_LOG2:0]  FILLCOUNT;
    bit  READY;
    bit  VALIDOUT;
    bit  NOTFULL;
    
    //Global signals
    bit to_reset=1;

    constraint valid_command {
        CMD inside {NOP, SCR, SCW, BLR, BLW};
    }
    constraint valid_size {
        if(CMD inside {NOP, SCR, SCW}) SZ=2'b00;
    }
    
    `uvm_object_utils_begin(host_tlm)
        `uvm_field_int(INITDDR, UVM_ALL_ON)
        `uvm_field_int(CMD, UVM_ALL_ON)
        `uvm_field_int(SZ, UVM_ALL_ON)
        `uvm_field_int(ADDR, UVM_ALL_ON)
        `uvm_field_int(DIN, UVM_ALL_ON)
        `uvm_field_int(DOUT, UVM_ALL_ON)
        `uvm_field_int(RADDR, UVM_ALL_ON)
        `uvm_field_int(FILLCOUNT, UVM_ALL_ON)
        `uvm_field_int(READY, UVM_ALL_ON)
        `uvm_field_int(VALIDOUT, UVM_ALL_ON)
        `uvm_field_int(NOTFULL, UVM_ALL_ON)
        `uvm_field_int(to_reset, UVM_ALL_ON)
    `uvm_object_utils_end


endclass
