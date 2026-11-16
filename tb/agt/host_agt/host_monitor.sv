class host_monitor #(
    type REQ = uvm_sequence_item,
    type DATA = uvm_sequence_item
) extends uvm_monitor;
    `uvm_component_param_utils(host_monitor #(REQ,DATA))
endclass