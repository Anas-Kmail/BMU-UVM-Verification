class bmu_env extends uvm_env;

    `uvm_component_utils(bmu_env)


    bmu_agent      agent;
    bmu_scoreboard scoreboard;
    bmu_coverage   coverage;


    // ============================================================
    // Constructor
    // ============================================================
    function new(
        string name = "bmu_env",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // ============================================================
    // Build Phase
    // ============================================================
    function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);


        agent =
            bmu_agent::type_id::create(
                "agent",
                this
            );


        scoreboard =
            bmu_scoreboard::type_id::create(
                "scoreboard",
                this
            );


        coverage =
            bmu_coverage::type_id::create(
                "coverage",
                this
            );

    endfunction


    // ============================================================
    // Connect Phase
    // ============================================================
    function void connect_phase(
        uvm_phase phase
    );

        super.connect_phase(phase);


        // Monitor -> Scoreboard
        agent.monitor.mon_ap.connect(
            scoreboard.analysis_imp
        );


        // Monitor -> Coverage
        agent.monitor.mon_ap.connect(
            coverage.analysis_export
        );

    endfunction


endclass