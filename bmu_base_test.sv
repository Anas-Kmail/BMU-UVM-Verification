class bmu_base_test extends uvm_test;

    `uvm_component_utils(bmu_base_test)

    bmu_env env;


    function new(
        string name = "bmu_base_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        env =
            bmu_env::type_id::create(
                "env",
                this
            );

    endfunction


    task run_phase(uvm_phase phase);

        bmu_reset_sequence reset_seq;
        bmu_base_sequence  seq;

        phase.raise_objection(this);


        reset_seq =
            bmu_reset_sequence::type_id::create(
                "reset_seq"
            );

        reset_seq.start(
            env.agent.sequencer
        );


        seq =
            bmu_base_sequence::type_id::create(
                "seq"
            );

        seq.start(
            env.agent.sequencer
        );


        #10;


        phase.drop_objection(this);

    endtask

endclass