module bmu_top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import rtl_pkg::*;
    import bmu_tb_pkg::*;


    // ============================================================
    // Clock
    // ============================================================

    logic clk;


    // ============================================================
    // Interface
    // ============================================================

    bmu_interface bmu_if(clk);


    // ============================================================
    // DUT
    // ============================================================

    Bit_Manipulation_Unit dut (

        .clk            (clk),

        .rst_l          (bmu_if.rst_l),
        .scan_mode      (bmu_if.scan_mode),
        .valid_in       (bmu_if.valid_in),

        .ap             (bmu_if.ap),

        .csr_ren_in     (bmu_if.csr_ren_in),
        .csr_rddata_in  (bmu_if.csr_rddata_in),

        .a_in           (bmu_if.a_in),
        .b_in           (bmu_if.b_in),

        .result_ff      (bmu_if.result_ff),
        .error          (bmu_if.error)

    );


    // ============================================================
    // SystemVerilog Assertions
    // ============================================================

    bmu_assertions bmu_sva (

        .clk        (clk),

        .rst_l      (bmu_if.rst_l),

        .valid_in   (bmu_if.valid_in),
        .scan_mode  (bmu_if.scan_mode),
        .txn_active (bmu_if.txn_active),

        .ap         (bmu_if.ap),

        .csr_ren_in (bmu_if.csr_ren_in),

        .result_ff  (bmu_if.result_ff),
        .error      (bmu_if.error)

    );


    // ============================================================
    // Clock Generation
    // ============================================================

    initial begin

        clk = 1'b0;

        forever
            #5 clk = ~clk;

    end


    // ============================================================
    // UVM Setup
    // ============================================================

    initial begin

        uvm_config_db #(virtual bmu_interface)::set(
            null,
            "*",
            "vif",
            bmu_if
        );

        run_test();

    end


endmodule