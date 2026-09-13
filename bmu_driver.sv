class bmu_driver extends uvm_driver #(bmu_sequence_item);

    `uvm_component_utils(bmu_driver)


    // ============================================================
    // Virtual Interface
    // ============================================================
    virtual bmu_interface vif;


    // ============================================================
    // Sequence Item
    // ============================================================
    bmu_sequence_item req;


    // ============================================================
    // Constructor
    // ============================================================
    function new(
        string name = "bmu_driver",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // ============================================================
    // Build Phase
    // ============================================================
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);


        if (!uvm_config_db #(virtual bmu_interface)::get(
                this,
                "",
                "vif",
                vif
            ))
        begin

            `uvm_fatal(
                "DRV",
                "Virtual interface not found"
            )

        end

    endfunction


    // ============================================================
    // Run Phase
    //
    // Back-to-back capable driver
    //
    // The driver checks for a new sequence item on every
    // negative edge.
    //
    // If an item exists:
    //
    //     negedge N      -> drive transaction
    //     posedge N+0.5  -> DUT samples transaction
    //     negedge N+1    -> monitor observes completed transaction
    //                      while driver can drive next transaction
    //
    // This allows one transaction every clock cycle.
    // ============================================================
    task run_phase(uvm_phase phase);

        // --------------------------------------------------------
        // Initial TB bookkeeping
        // --------------------------------------------------------
        vif.txn_active = 1'b0;


        forever begin


            // ====================================================
            // Wait for the driving edge
            // ====================================================
            @(vif.drv_cb);


            // ====================================================
            // Important:
            //
            // Clear local handle before try_next_item().
            //
            // try_next_item() is non-blocking.
            //
            // Therefore, if no sequence item is currently ready,
            // the driver can simply create an idle TB cycle instead
            // of blocking forever with txn_active still high.
            // ====================================================
            req = null;


            seq_item_port.try_next_item(req);


            // ====================================================
            // A new transaction is available
            // ====================================================
            if (req != null) begin


                // ------------------------------------------------
                // Mark this cycle as a real TB transaction
                // ------------------------------------------------
                vif.drv_cb.txn_active <= 1'b1;


                // ------------------------------------------------
                // Drive DUT inputs
                // ------------------------------------------------
                vif.drv_cb.rst_l         <= req.rst_l;
                vif.drv_cb.scan_mode     <= req.scan_mode;
                vif.drv_cb.valid_in      <= req.valid_in;

                vif.drv_cb.ap            <= req.ap;

                vif.drv_cb.csr_ren_in    <= req.csr_ren_in;
                vif.drv_cb.csr_rddata_in <= req.csr_rddata_in;

                vif.drv_cb.a_in          <= req.a_in;
                vif.drv_cb.b_in          <= req.b_in;


                // ------------------------------------------------
                // DUT samples the transaction on the next posedge
                // ------------------------------------------------
                @(posedge vif.clk);


                // ------------------------------------------------
                // Tell sequencer that the item has completed
                // ------------------------------------------------
                seq_item_port.item_done();


            end


            // ====================================================
            // No transaction available
            // ====================================================
            else begin

                // ------------------------------------------------
                // txn_active is TB-only bookkeeping.
                //
                // We do NOT need to modify DUT inputs here.
                //
                // txn_active = 0 tells the monitor:
                //
                // "Do not create a transaction from this cycle."
                // ------------------------------------------------
                vif.drv_cb.txn_active <= 1'b0;

            end


        end

    endtask


endclass