class bmu_sanity_test extends bmu_base_test;

    `uvm_component_utils(bmu_sanity_test)


    function new(
        string name = "bmu_sanity_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    function void build_phase(uvm_phase phase);

        bmu_base_sequence::type_id::set_type_override(
            bmu_sanity_sequence::get_type()
        );

        super.build_phase(phase);

    endfunction

endclass