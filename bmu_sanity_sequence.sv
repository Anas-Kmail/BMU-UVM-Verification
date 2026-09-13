class bmu_sanity_sequence extends bmu_base_sequence;

    `uvm_object_utils(bmu_sanity_sequence)


    function new(string name = "bmu_sanity_sequence");
        super.new(name);
    endfunction


    // =========================================
    // Helper task:
    // run one directed BMU operation
    // =========================================
    task run_op(
        bmu_op_e            operation,
        logic signed [31:0] a,
        logic        [31:0] b
    );

        bmu_directed_sequence seq;


        seq =
            bmu_directed_sequence::type_id::create(
                "directed_seq"
            );


        seq.op      = operation;
        seq.a_value = a;
        seq.b_value = b;


        seq.start(m_sequencer);

    endtask


    // =========================================
    // Main sanity sequence
    // =========================================
    virtual task body();


        // =====================================
        // CSR WRITE
        // =====================================

        run_op(
            OP_CSR_WRITE_REG,
            32'h1234_5678,
            32'hABCD_EF12
        );

        run_op(
            OP_CSR_WRITE_IMM,
            32'h1234_5678,
            32'hABCD_EF12
        );


        // =====================================
        // LOGICAL
        // =====================================

        run_op(
            OP_OR,
            32'h0000_FF00,
            32'h00FF_0000
        );

        run_op(
            OP_ORN,
            32'hFFFF_0000,
            32'h0000_00FF
        );

        run_op(
            OP_XOR,
            32'hF0F0_F0F0,
            32'h0F0F_0F0F
        );

        run_op(
            OP_XNOR,
            32'hAAAA_AAAA,
            32'h5555_5555
        );


        // =====================================
        // SHIFT / MASK
        // =====================================

        run_op(
            OP_SRL,
            32'hF000_0000,
            32'd4
        );

        run_op(
            OP_SRA,
            32'hF000_0000,
            32'd4
        );

        run_op(
            OP_ROR,
            32'h1234_5678,
            32'd8
        );

        run_op(
            OP_BINV,
            32'hFFFF_FFFF,
            32'd2
        );

        run_op(
            OP_SH2ADD,
            32'd4,
            32'd7
        );


        // =====================================
        // ARITHMETIC
        // =====================================

        run_op(
            OP_SUB,
            32'd20,
            32'd7
        );


        // =====================================
        // SLT / SLTU
        // =====================================

        run_op(
            OP_SLT,
            32'hFFFF_FFFE,
            32'd1
        );

        run_op(
            OP_SLTU,
            32'hFFFF_FFFF,
            32'd1
        );


        // =====================================
        // CTZ
        // =====================================

        run_op(
            OP_CTZ,
            32'h0000_0100,
            32'd0
        );

        run_op(
            OP_CTZ,
            32'h0000_0000,
            32'd0
        );


        // =====================================
        // CPOP
        // =====================================

        run_op(
            OP_CPOP,
            32'hF0F0_F00F,
            32'd0
        );


        // =====================================
        // SEXT.B
        // =====================================

        run_op(
            OP_SEXTB,
            32'h0000_0080,
            32'd0
        );


        // =====================================
        // MAX
        // =====================================

        run_op(
            OP_MAX,
            32'd10,
            32'd20
        );


        // =====================================
        // PACK
        // =====================================

        run_op(
            OP_PACK,
            32'h1234_5678,
            32'hABCD_EF12
        );


        // =====================================
        // GREV
        // =====================================

        run_op(
            OP_GREV,
            32'h1234_5678,
            32'd24
        );


    endtask

endclass