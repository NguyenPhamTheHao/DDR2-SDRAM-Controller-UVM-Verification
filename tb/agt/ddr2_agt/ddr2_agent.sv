class ddr2_agent #(
    type HOST_PKT = host_tlm,
    type DATA = data_tlm 
) extends uvm_agent;
    
    `uvm_component_param_utils(ddr2_agent #(HOST_PKT,DATA))

    typedef ddr2_driver ddr2_driver_t;
    typedef ddr2_monitor #(HOST_PKT,DATA) ddr2_monitor_t;

    string my_name;

    ddr2_driver_t ddr2_driver;
    ddr2_monitor_t ddr2_monitor;

    //Actual captured host cfg from ddr2_monitor (Device interface)
    uvm_analysis_port #(HOST_PKT) act_host_cfg_port;
    
    //Expected data transfer from RAM to Controller
    uvm_analysis_port #(DATA) exp_ram_tx_port;

    function new(string name = "ddr2_agent", uvm_component = null);
        super.new(name,parent);
        my_name = name;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ddr2_driver = ddr2_driver_t::type_id::create("ddr2_driver",this);
        ddr2_monitor= ddr2_monitor_t::type_id::create("ddr2_monitor",this);
        act_host_cfg_port = new("act_host_cfg_port",this);
        exp_ram_tx_port = new("exp_ram_tx_port",this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ddr2_monitor.act_host_cfg_port.connect(this.act_host_cfg_port);
        ddr2_monitor.exp_ram_tx_port.connect(this.exp_ram_tx_port);
    endfunction
endclass
