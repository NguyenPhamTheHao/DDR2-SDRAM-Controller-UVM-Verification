class host_driver #(
    type REQ = uvm_sequence_item
) extends uvm_driver;
    `uvm_component_param_utils(host_driver #(REQ))
endclass