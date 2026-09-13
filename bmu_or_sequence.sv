class bmu_or_sequence extends uvm_sequence #(bmu_sequence_item);

    `uvm_object_utils(bmu_or_sequence)

    bmu_sequence_item req;

    function new(string name = "bmu_or_sequence");
        super.new(name);
    endfunction


    task body();

        req = bmu_sequence_item::type_id::create("req");

        start_item(req);

        req.rst_l          = 1'b1;
        req.scan_mode      = 1'b0;
        req.valid_in       = 1'b1;

        req.csr_ren_in     = 1'b0;
        req.csr_rddata_in  = 32'h0;

        req.a_in           = 32'h0000_FF00;
        req.b_in           = 32'h00FF_0000;

        // Clear all control signals first
        req.ap             = '0;

        // Standard OR
        req.ap.lor         = 1'b1;
        req.ap.zbb         = 1'b0;

        finish_item(req);

    endtask

endclass