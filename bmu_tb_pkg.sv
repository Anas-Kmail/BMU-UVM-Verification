package bmu_tb_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import rtl_pkg::*;


    // -----------------------------------------
    // Operations explicitly detailed in spec
    // -----------------------------------------
    typedef enum {

        OP_CSR_WRITE_REG,
        OP_CSR_WRITE_IMM,

        OP_OR,
        OP_ORN,

        OP_XOR,
        OP_XNOR,

        OP_SRL,
        OP_SRA,
        OP_ROR,

        OP_BINV,
        OP_SH2ADD,

        OP_SUB,

        OP_SLT,
        OP_SLTU,

        OP_CTZ,
        OP_CPOP,

        OP_SEXTB,

        OP_MAX,

        OP_PACK,

        OP_GREV

    } bmu_op_e;


    // =========================================
    // TRANSACTION + SEQUENCER
    // =========================================
    `include "bmu_sequence_item.sv"
    `include "bmu_sequencer.sv"


    // =========================================
    // SEQUENCES
    // =========================================
    `include "bmu_reset_sequence.sv"

    `include "bmu_base_sequence.sv"

    `include "bmu_directed_sequence.sv"
    `include "bmu_sanity_sequence.sv"
    `include "bmu_error_sequence.sv"

    `include "bmu_random_sequence.sv"

    // Stress sequence extends random sequence
    `include "bmu_stress_sequence.sv"


    // =========================================
    // AGENT COMPONENTS
    // =========================================
    `include "bmu_driver.sv"
    `include "bmu_monitor.sv"

    `include "bmu_agent.sv"


    // =========================================
    // CHECKING + COVERAGE
    // =========================================
    `include "bmu_scoreboard.sv"
    `include "bmu_coverage.sv"


    // =========================================
    // ENVIRONMENT
    // =========================================
    `include "bmu_env.sv"


    // =========================================
    // TESTS
    // =========================================
    `include "bmu_base_test.sv"

    `include "bmu_sanity_test.sv"
    `include "bmu_error_test.sv"

    `include "bmu_random_test.sv"

    // Stress test
    `include "bmu_stress_test.sv"


endpackage