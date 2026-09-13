class bmu_reset_sequence extends uvm_sequence #(bmu_sequence_item);

    `uvm_object_utils(bmu_reset_sequence)

    bmu_sequence_item reset_assert_req;
    bmu_sequence_item reset_deassert_req;

    function new(string name = "bmu_reset_sequence");
        super.new(name);
    endfunction


    task body();

        // -------------------------
        // Assert reset
        // -------------------------
        reset_assert_req =
            bmu_sequence_item::type_id::create("reset_assert_req");

        start_item(reset_assert_req);

        reset_assert_req.rst_l          = 1'b0;
        reset_assert_req.scan_mode      = 1'b0;
        reset_assert_req.valid_in       = 1'b0;
        reset_assert_req.csr_ren_in     = 1'b0;
        reset_assert_req.csr_rddata_in  = '0;
        reset_assert_req.a_in           = '0;
        reset_assert_req.b_in           = '0;
        reset_assert_req.ap             = '0;

        finish_item(reset_assert_req);


        // -------------------------
        // Deassert reset
        // -------------------------
        reset_deassert_req =
            bmu_sequence_item::type_id::create("reset_deassert_req");

        start_item(reset_deassert_req);

        reset_deassert_req.rst_l          = 1'b1;
        reset_deassert_req.scan_mode      = 1'b0;
        reset_deassert_req.valid_in       = 1'b0;
        reset_deassert_req.csr_ren_in     = 1'b0;
        reset_deassert_req.csr_rddata_in  = '0;
        reset_deassert_req.a_in           = '0;
        reset_deassert_req.b_in           = '0;
        reset_deassert_req.ap             = '0;

        finish_item(reset_deassert_req);

    endtask

endclass