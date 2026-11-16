class ddr2_monitor #(
    type HOST_PKT = uvm_sequence_item,
    type DATA = uvm_sequence_item
) extends uvm_monitor;
    `uvm_component_param_utils(ddr2_monitor#(HOST_PKT,DATA))
endclass