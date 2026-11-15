class ddr2_tlm extends uvm_sequence_item;
    string my_name;
    function new(string name = "ddr2_tlm");
        super.new(name);
        my_name = name;
    endfunction

    bit [(1<<RANK_BITS)-1:0]   C0_CSBAR_PAD;
    bit         C0_RASBAR_PAD;
    bit         C0_CASBAR_PAD;
    bit         C0_WEBAR_PAD;
    bit [1:0]   C0_BA_PAD;
    bit [12:0]  C0_A_PAD;
    bit [1:0]   C0_DM_PAD;
    bit         C0_ODT_PAD;
    bit         C0_CK_PAD;
    bit         C0_CKBAR_PAD;
    bit         C0_CKE_PAD;
    // Captured bus value; this transaction is populated by the DDR2 monitor.
    bit [DATA_WIDTH-1:0]  C0_DQ_PAD;
    bit [1:0]   C0_DQS_PAD;
    bit [1:0]   C0_DQSBAR_PAD;

    `uvm_object_utils_begin(ddr2_tlm)
        `uvm_field_int(C0_CSBAR_PAD, UVM_ALL_ON)
        `uvm_field_int(C0_RASBAR_PAD, UVM_ALL_ON)
        `uvm_field_int(C0_CASBAR_PAD, UVM_ALL_ON)
        `uvm_field_int(C0_WEBAR_PAD, UVM_ALL_ON)
        `uvm_field_int(C0_BA_PAD, UVM_ALL_ON)
        `uvm_field_int(C0_A_PAD, UVM_ALL_ON)
        `uvm_field_int(C0_DM_PAD, UVM_ALL_ON)
        `uvm_field_int(C0_ODT_PAD, UVM_ALL_ON)
        `uvm_field_int(C0_CK_PAD, UVM_ALL_ON)
        `uvm_field_int(C0_CKBAR_PAD, UVM_ALL_ON)
        `uvm_field_int(C0_CKE_PAD, UVM_ALL_ON)
        `uvm_field_int(C0_DQ_PAD, UVM_ALL_ON)
        `uvm_field_int(C0_DQS_PAD, UVM_ALL_ON)
        `uvm_field_int(C0_DQSBAR_PAD, UVM_ALL_ON)
    `uvm_object_utils_end


endclass
