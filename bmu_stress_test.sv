class bmu_stress_test extends bmu_base_test;

    `uvm_component_utils(bmu_stress_test)


    // ============================================================
    // Constructor
    // ============================================================
    function new(
        string name = "bmu_stress_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // ============================================================
    // Build Phase
    // ============================================================
    virtual function void build_phase(uvm_phase phase);


        // --------------------------------------------------------
        // Factory Override
        //
        // Base test creates:
        //
        //      bmu_base_sequence
        //
        // We replace it with:
        //
        //      bmu_stress_sequence
        //
        // --------------------------------------------------------
        bmu_base_sequence::type_id::set_type_override(
            bmu_stress_sequence::get_type()
        );


        super.build_phase(phase);


        `uvm_info(
            "STRESS_TEST",
            "Factory override: bmu_base_sequence -> bmu_stress_sequence",
            UVM_LOW
        )


    endfunction


endclass