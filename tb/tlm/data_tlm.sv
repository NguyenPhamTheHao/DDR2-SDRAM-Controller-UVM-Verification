class data_tlm extends uvm_sequence_item;
    bit [DATA_WIDTH-1:0] read_data;

    function new(string name = "data_tlm");
        super.new(name);
    endfunction

    function void do_copy(uvm_object rhs);
        `uvm_object_utils_begin(data_tlm)
            `uvm_field_int(read_data, UVM_ALL_ON)
        `uvm_object_utils_end
        data_tlm der_type;
        super.do_copy(rhs);
        $cast(der_type,rhs);
        read_data = der_type.read_data;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        data_tlm der_type;
        do_compare = super.do_compare(rhs,comparer);
        $cast(der_type,rhs);
        do_compare &= comparer.compare_field_int("read_data",read_data,der_type.read_data,$bits(read_data));
    endfunction

endclass