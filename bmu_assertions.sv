module bmu_assertions
(
    input logic clk,
    input logic rst_l,

    input logic valid_in,
    input logic scan_mode,
    input logic txn_active,

    input rtl_pkg::rtl_alu_pkt_t ap,

    input logic csr_ren_in,

    input logic [31:0] result_ff,
    input logic        error
);


    // ============================================================
    // 1. RESET MUST CLEAR result_ff
    // ============================================================
    //
    // BMU reset is synchronous and active-low.
    //
    // If rst_l is LOW at a rising edge,
    // result_ff must be zero at the next sampled clock.
    //

    property p_reset_clears_result;

        @(posedge clk)

        (!rst_l)
        |=>
        (result_ff == 32'h0000_0000);

    endproperty


    a_reset_clears_result:
        assert property (p_reset_clears_result)

        else
            $error(
                "[SVA] RESET ERROR: result_ff was not cleared to zero"
            );


    // ============================================================
    // 2. ERROR MUST BE ZERO DURING RESET
    // ============================================================
    //
    // error is combinational and must be 0 whenever rst_l = 0.
    //

    property p_reset_clears_error;

        @(posedge clk)

        (!rst_l)
        |->
        (error == 1'b0);

    endproperty


    a_reset_clears_error:
        assert property (p_reset_clears_error)

        else
            $error(
                "[SVA] RESET ERROR: error was not zero during reset"
            );


    // ============================================================
    // 3. result_ff MUST HOLD WHEN valid_in = 0
    // ============================================================
    //
    // If valid_in is LOW, result_ff must keep its previous value.
    //
    // disable iff prevents this assertion from being evaluated
    // when reset becomes active.
    //

    property p_result_hold_when_invalid;

        @(posedge clk)

        disable iff (!rst_l)

        (!valid_in)
        |=>
        (result_ff == $past(result_ff));

    endproperty


    a_result_hold_when_invalid:
        assert property (p_result_hold_when_invalid)

        else
            $error(
                "[SVA] HOLD ERROR: result_ff changed while valid_in = 0"
            );


    // ============================================================
    // 4. CSR + AP CONFLICT MUST ASSERT ERROR
    // ============================================================
    //
    // csr_ren_in and any active operation in ap are illegal
    // when used together.
    //
    // txn_active ensures that the assertion evaluates an actual
    // testbench transaction rather than stale bus values.
    //

    property p_csr_ap_conflict_error;

        @(posedge clk)

        disable iff (!rst_l)

        (
            txn_active &&
            csr_ren_in &&
            (ap != '0)
        )
        |->
        (error == 1'b1);

    endproperty


    a_csr_ap_conflict_error:
        assert property (p_csr_ap_conflict_error)

        else
            $error(
                "[SVA] ERROR SIGNAL ERROR: CSR/AP conflict did not assert error"
            );


    // ============================================================
    // 5. SH2ADD WITHOUT ZBA MUST ASSERT ERROR
    // ============================================================

    property p_sh2add_without_zba_error;

        @(posedge clk)

        disable iff (!rst_l)

        (
            txn_active &&
            ap.sh2add &&
            !ap.zba
        )
        |->
        (error == 1'b1);

    endproperty


    a_sh2add_without_zba_error:
        assert property (p_sh2add_without_zba_error)

        else
            $error(
                "[SVA] ERROR SIGNAL ERROR: SH2ADD without ZBA did not assert error"
            );


    // ============================================================
    // 6. SUB WITH ZBA MUST ASSERT ERROR
    // ============================================================

    property p_sub_with_zba_error;

        @(posedge clk)

        disable iff (!rst_l)

        (
            txn_active &&
            ap.sub &&
            ap.zba
        )
        |->
        (error == 1'b1);

    endproperty


    a_sub_with_zba_error:
        assert property (p_sub_with_zba_error)

        else
            $error(
                "[SVA] ERROR SIGNAL ERROR: SUB with ZBA did not assert error"
            );


    // ============================================================
    // 7. OR + XOR CONFLICT MUST ASSERT ERROR
    // ============================================================

    property p_or_xor_conflict_error;

        @(posedge clk)

        disable iff (!rst_l)

        (
            txn_active &&
            ap.lor &&
            ap.lxor
        )
        |->
        (error == 1'b1);

    endproperty


    a_or_xor_conflict_error:
        assert property (p_or_xor_conflict_error)

        else
            $error(
                "[SVA] ERROR SIGNAL ERROR: OR/XOR conflict did not assert error"
            );


    // ============================================================
    // 8. SRL + OR CONFLICT MUST ASSERT ERROR
    // ============================================================

    property p_srl_or_conflict_error;

        @(posedge clk)

        disable iff (!rst_l)

        (
            txn_active &&
            ap.srl &&
            ap.lor
        )
        |->
        (error == 1'b1);

    endproperty


    a_srl_or_conflict_error:
        assert property (p_srl_or_conflict_error)

        else
            $error(
                "[SVA] ERROR SIGNAL ERROR: SRL/OR conflict did not assert error"
            );


    // ============================================================
    // 9. SRA + OR CONFLICT MUST ASSERT ERROR
    // ============================================================

    property p_sra_or_conflict_error;

        @(posedge clk)

        disable iff (!rst_l)

        (
            txn_active &&
            ap.sra &&
            ap.lor
        )
        |->
        (error == 1'b1);

    endproperty


    a_sra_or_conflict_error:
        assert property (p_sra_or_conflict_error)

        else
            $error(
                "[SVA] ERROR SIGNAL ERROR: SRA/OR conflict did not assert error"
            );


    // ============================================================
    // 10. ROR + OR CONFLICT MUST ASSERT ERROR
    // ============================================================

    property p_ror_or_conflict_error;

        @(posedge clk)

        disable iff (!rst_l)

        (
            txn_active &&
            ap.ror &&
            ap.lor
        )
        |->
        (error == 1'b1);

    endproperty


    a_ror_or_conflict_error:
        assert property (p_ror_or_conflict_error)

        else
            $error(
                "[SVA] ERROR SIGNAL ERROR: ROR/OR conflict did not assert error"
            );


    // ============================================================
    // 11. BINV + OR CONFLICT MUST ASSERT ERROR
    // ============================================================

    property p_binv_or_conflict_error;

        @(posedge clk)

        disable iff (!rst_l)

        (
            txn_active &&
            ap.binv &&
            ap.lor
        )
        |->
        (error == 1'b1);

    endproperty


    a_binv_or_conflict_error:
        assert property (p_binv_or_conflict_error)

        else
            $error(
                "[SVA] ERROR SIGNAL ERROR: BINV/OR conflict did not assert error"
            );


    // ============================================================
    // 12. GREV + OR CONFLICT MUST ASSERT ERROR
    // ============================================================

    property p_grev_or_conflict_error;

        @(posedge clk)

        disable iff (!rst_l)

        (
            txn_active &&
            ap.grev &&
            ap.lor
        )
        |->
        (error == 1'b1);

    endproperty


    a_grev_or_conflict_error:
        assert property (p_grev_or_conflict_error)

        else
            $error(
                "[SVA] ERROR SIGNAL ERROR: GREV/OR conflict did not assert error"
            );


    // ============================================================
    // 13. SCAN MODE MUST REMAIN DISABLED
    // ============================================================
    //
    // scan_mode has no functional use in this verification setup.
    // The testbench is required to keep it at zero.
    //

    property p_scan_mode_disabled;

        @(posedge clk)

        (scan_mode == 1'b0);

    endproperty


    a_scan_mode_disabled:
        assert property (p_scan_mode_disabled)

        else
            $error(
                "[SVA] TESTBENCH ERROR: scan_mode must remain 0"
            );


endmodule