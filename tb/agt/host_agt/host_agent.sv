class host_agent #(
    type REQ  = host_tlm,
    type DATA = data_tlm
) extends uvm_agent;
    
    `uvm_component_param_utils(host_agent #(REQ,DATA))

    typedef host_driver #(REQ) host_driver_t;
    typedef host_monitor #(REQ,DATA) host_monitor_t;
    typedef uvm_sequencer #(REQ) host_sequencer_t;

    string my_name;

    host_driver_t host_driver;
    host_monitor_t host_monitor;
    host_sequencer_t host_sequencer;

    //Expected captured configuration from Host
    uvm_analysis_port #(REQ) exp_host_cfg_port;

    //Actual read data return from FIFO
    uvm_analysis_port #(DATA) act_controller_rx_port;

    function new(string name = "host_agent", uvm_component parent = null);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(is_active == UVM_ACTIVE) begin
            host_driver = host_driver_t::type_id::create("host_driver",this);
            host_sequencer = host_sequencer_t::type_id::create("host_sequencer",this);
        end

        host_monitor = host_monitor_t::type_id::create("host_monitor",this);

        exp_host_cfg_port = new("exp_host_cfg_port",this);
        act_controller_rx_port = new("act_controller_rx_port",this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        host_monitor.exp_host_cfg_port.connect(this.exp_host_cfg_port);
        host_monitor.act_controller_rx_port.connect(this.act_controller_rx_port);

        if(is_active == UVM_ACTIVE) begin
            host_driver.seq_item_port.connect(host_sequencer.seq_item_export);
        end
    endfunction
endclass