class bmu_random_test extends bmu_base_test;

    `uvm_component_utils(bmu_random_test)


    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    function new(
        string name = "bmu_random_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // ============================================================
    // BUILD PHASE
    // ============================================================
    //
    // bmu_base_test normally asks the factory to create:
    //
    //      bmu_base_sequence
    //
    // We tell the factory:
    //
    //      whenever somebody requests bmu_base_sequence
    //
    //                   ↓
    //
    //      create bmu_random_sequence instead
    //
    // Therefore we reuse the SAME run_phase from bmu_base_test.
    //
    // No duplicated test execution code is needed.
    // ============================================================

    virtual function void build_phase(uvm_phase phase);


        // --------------------------------------------------------
        // FACTORY TYPE OVERRIDE
        // --------------------------------------------------------
        //
        // IMPORTANT:
        // The override is registered BEFORE super.build_phase().
        //
        // --------------------------------------------------------

        bmu_base_sequence::type_id::set_type_override(
            bmu_random_sequence::get_type()
        );


        // Build the normal base-test environment.
        super.build_phase(phase);


        `uvm_info(
            "RANDOM_TEST",
            "Factory override: bmu_base_sequence -> bmu_random_sequence",
            UVM_LOW
        )


    endfunction


endclass