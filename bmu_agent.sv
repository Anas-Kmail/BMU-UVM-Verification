class bmu_agent extends uvm_agent;

    `uvm_component_utils(bmu_agent)

    bmu_sequencer sequencer;
    bmu_driver    driver;
    bmu_monitor   monitor;


    function new(string name = "bmu_agent",
                 uvm_component parent = null);

        super.new(name, parent);

    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        sequencer = bmu_sequencer::type_id::create(
                        "sequencer", this);

        driver = bmu_driver::type_id::create(
                        "driver", this);

        monitor = bmu_monitor::type_id::create(
                        "monitor", this);

    endfunction


    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        driver.seq_item_port.connect(
            sequencer.seq_item_export
        );

    endfunction

endclass