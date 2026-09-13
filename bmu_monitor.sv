class bmu_monitor extends uvm_monitor;

    `uvm_component_utils(bmu_monitor)


    virtual bmu_interface vif;


    uvm_analysis_port #(
        bmu_sequence_item
    ) mon_ap;


    // ============================================================
    // Constructor
    // ============================================================
    function new(
        string name = "bmu_monitor",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // ============================================================
    // Build Phase
    // ============================================================
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        mon_ap = new(
            "mon_ap",
            this
        );


        if (!uvm_config_db #(virtual bmu_interface)::get(
                this,
                "",
                "vif",
                vif
            ))
        begin

            `uvm_fatal(
                "MON",
                "Virtual interface not found"
            )

        end

    endfunction


    // ============================================================
    // Run Phase
    // ============================================================
    task run_phase(uvm_phase phase);

        bmu_sequence_item tr;


        forever begin

            // Driver drives at negedge.
            //
            // DUT samples at the following posedge.
            //
            // We observe at the next negedge so result_ff
            // already contains the registered output.
            @(negedge vif.clk);


            // txn_active is TESTBENCH bookkeeping.
            //
            // It tells us:
            // "this is a transaction that should be checked"
            //
            // It is intentionally different from valid_in.
            if (vif.txn_active == 1'b1) begin

                tr =
                    bmu_sequence_item::type_id::create(
                        "tr"
                    );


                // ------------------------------------------------
                // Inputs
                // ------------------------------------------------
                tr.rst_l =
                    vif.rst_l;

                tr.scan_mode =
                    vif.scan_mode;

                tr.valid_in =
                    vif.valid_in;

                tr.ap =
                    vif.ap;

                tr.csr_ren_in =
                    vif.csr_ren_in;

                tr.csr_rddata_in =
                    vif.csr_rddata_in;

                tr.a_in =
                    vif.a_in;

                tr.b_in =
                    vif.b_in;


                // ------------------------------------------------
                // DUT outputs
                // ------------------------------------------------
                tr.result_ff =
                    vif.result_ff;

                tr.error =
                    vif.error;


                // ------------------------------------------------
                // Send transaction to scoreboard
                // ------------------------------------------------
                mon_ap.write(tr);

            end

        end

    endtask


endclass