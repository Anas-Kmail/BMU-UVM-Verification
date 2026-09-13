class bmu_error_sequence extends bmu_base_sequence;

    `uvm_object_utils(bmu_error_sequence)


    function new(string name = "bmu_error_sequence");
        super.new(name);
    endfunction


    // ============================================================
    // Helper task
    // Sends one intentionally-invalid transaction
    // ============================================================
    task send_invalid_item(
        input rtl_alu_pkt_t       ap_value,
        input logic               csr_ren_value,
        input logic               valid_value,
        input logic signed [31:0] a_value,
        input logic        [31:0] b_value
    );

        bmu_sequence_item req;

        req = bmu_sequence_item::type_id::create("req");

        start_item(req);

        // Common values
        req.rst_l          = 1'b1;
        req.scan_mode      = 1'b0;

        // valid_in is now configurable
        req.valid_in       = valid_value;

        req.csr_ren_in     = csr_ren_value;
        req.csr_rddata_in  = '0;

        req.a_in           = a_value;
        req.b_in           = b_value;

        req.ap             = ap_value;

        finish_item(req);

    endtask


    // ============================================================
    // ERROR SEQUENCE
    // ============================================================
    task body();

        rtl_alu_pkt_t ap_value;


        // ========================================================
        // CASE 1
        // CSR read active together with an AP operation
        //
        // Invalid:
        // csr_ren_in = 1
        // ap.lor     = 1
        //
        // Expected:
        // result = 0
        // error  = 1
        // ========================================================
        ap_value = '0;

        ap_value.lor = 1'b1;

        send_invalid_item(
            ap_value,
            1'b1,   // csr_ren_in
            1'b1,   // valid_in
            32'h0000_FF00,
            32'h00FF_0000
        );


        // ========================================================
        // CASE 2
        // SH2ADD without ZBA
        //
        // Expected:
        // result = 0
        // error  = 1
        // ========================================================
        ap_value = '0;

        ap_value.sh2add = 1'b1;
        ap_value.zba    = 1'b0;

        send_invalid_item(
            ap_value,
            1'b0,   // csr_ren_in
            1'b1,   // valid_in
            32'h0000_0004,
            32'h0000_0007
        );


        // ========================================================
        // CASE 3
        // SUB with ZBA asserted
        //
        // Expected:
        // result = 0
        // error  = 1
        // ========================================================
        ap_value = '0;

        ap_value.sub = 1'b1;
        ap_value.zba = 1'b1;

        send_invalid_item(
            ap_value,
            1'b0,
            1'b1,
            32'h0000_0014,
            32'h0000_0007
        );


        // ========================================================
        // CASE 4
        // OR active together with XOR
        //
        // Invalid multiple AP operations
        //
        // Expected:
        // result = 0
        // error  = 1
        // ========================================================
        ap_value = '0;

        ap_value.lor  = 1'b1;
        ap_value.lxor = 1'b1;

        send_invalid_item(
            ap_value,
            1'b0,
            1'b1,
            32'h0000_FF00,
            32'h00FF_0000
        );


        // ========================================================
        // CASE 5
        // XOR active together with OR
        //
        // Same conflict family, but different data values
        //
        // Expected:
        // result = 0
        // error  = 1
        // ========================================================
        ap_value = '0;

        ap_value.lxor = 1'b1;
        ap_value.lor  = 1'b1;

        send_invalid_item(
            ap_value,
            1'b0,
            1'b1,
            32'hF0F0_F0F0,
            32'h0F0F_0F0F
        );


        // ========================================================
        // CASE 6
        // SRL active together with OR
        //
        // Expected:
        // result = 0
        // error  = 1
        // ========================================================
        ap_value = '0;

        ap_value.srl = 1'b1;
        ap_value.lor = 1'b1;

        send_invalid_item(
            ap_value,
            1'b0,
            1'b1,
            32'hF000_0000,
            32'h0000_0004
        );


        // ========================================================
        // CASE 7
        // SRA active together with OR
        //
        // Expected:
        // result = 0
        // error  = 1
        // ========================================================
        ap_value = '0;

        ap_value.sra = 1'b1;
        ap_value.lor = 1'b1;

        send_invalid_item(
            ap_value,
            1'b0,
            1'b1,
            32'hF000_0000,
            32'h0000_0004
        );


        // ========================================================
        // CASE 8
        // ROR active together with OR
        //
        // Expected:
        // result = 0
        // error  = 1
        // ========================================================
        ap_value = '0;

        ap_value.ror = 1'b1;
        ap_value.lor = 1'b1;

        send_invalid_item(
            ap_value,
            1'b0,
            1'b1,
            32'h1234_5678,
            32'h0000_0008
        );


        // ========================================================
        // CASE 9
        // BINV active together with OR
        //
        // Expected:
        // result = 0
        // error  = 1
        // ========================================================
        ap_value = '0;

        ap_value.binv = 1'b1;
        ap_value.lor  = 1'b1;

        send_invalid_item(
            ap_value,
            1'b0,
            1'b1,
            32'hFFFF_FFFF,
            32'h0000_0002
        );


        // ========================================================
        // CASE 10
        // GREV active together with OR
        //
        // b[4:0] is kept valid = 24.
        // The error is caused ONLY by the AP conflict.
        //
        // Expected:
        // result = 0
        // error  = 1
        // ========================================================
        ap_value = '0;

        ap_value.grev = 1'b1;
        ap_value.lor  = 1'b1;

        send_invalid_item(
            ap_value,
            1'b0,
            1'b1,
            32'h1234_5678,
            32'h0000_0018
        );


        // ========================================================
        // CASE 11
        // Error must be independent of valid_in
        //
        // CSR read is active together with an AP operation,
        // but valid_in = 0.
        //
        // According to the clarification:
        // error is independent of valid_in.
        //
        // Expected:
        // error = 1
        //
        // result_ff must HOLD its previous value
        // because valid_in = 0.
        // ========================================================
        ap_value = '0;

        ap_value.lor = 1'b1;

        send_invalid_item(
            ap_value,
            1'b1,   // csr_ren_in
            1'b0,   // valid_in
            32'hAAAA_AAAA,
            32'h5555_5555
        );

    endtask

endclass