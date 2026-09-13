class bmu_random_sequence extends bmu_base_sequence;

    `uvm_object_utils(bmu_random_sequence)


    // ============================================================
    // RANDOM VARIABLES
    // ============================================================
    //
    // We randomize:
    //   1. The BMU operation
    //   2. Operand A
    //   3. Operand B
    //
    // The actual AP control structure will be created later
    // depending on the selected operation.
    // ============================================================

    rand bmu_op_e            rand_op;
    rand logic signed [31:0] rand_a;
    rand logic        [31:0] rand_b;


    // ============================================================
    // LEGAL OPERATION CONSTRAINT
    // ============================================================
    //
    // Only operations that are part of our current verification
    // scope are allowed.
    //
    // This prevents randomization from generating unsupported
    // operations.
    // ============================================================

    constraint c_legal_operation {

        rand_op inside {

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

        };

    }


    // ============================================================
    // GREV CONSTRAINT
    // ============================================================
    //
    // The verified GREV behavior is byte reversal.
    //
    // For the supported GREV encoding:
    //
    //      b_in[4:0] = 24
    //
    // Therefore random GREV transactions must use this encoding.
    // ============================================================

    constraint c_grev_shamt {

        if (rand_op == OP_GREV)
            rand_b[4:0] == 5'd24;

    }


    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    function new(string name = "bmu_random_sequence");

        super.new(name);

    endfunction


    // ============================================================
    // BUILD AP CONTROL STRUCTURE
    // ============================================================
    //
    // rand_op is a simple enum used by the testbench.
    //
    // The DUT does NOT receive an opcode.
    //
    // The DUT receives the rtl_alu_pkt_t structure "ap".
    //
    // Therefore this function converts:
    //
    //        rand_op
    //
    //           ↓
    //
    //      correct ap bits
    //
    // Only the required control bits are asserted.
    // Everything else remains zero.
    // ============================================================

    function automatic rtl_alu_pkt_t
        build_ap(input bmu_op_e op);

        rtl_alu_pkt_t temp_ap;


        // Start with every AP field equal to zero.
        temp_ap = '0;


        case (op)


            // ====================================================
            // CSR WRITE REGISTER
            // ====================================================

            OP_CSR_WRITE_REG: begin

                temp_ap.csr_write = 1'b1;
                temp_ap.csr_imm   = 1'b0;

            end


            // ====================================================
            // CSR WRITE IMMEDIATE
            // ====================================================

            OP_CSR_WRITE_IMM: begin

                temp_ap.csr_write = 1'b1;
                temp_ap.csr_imm   = 1'b1;

            end


            // ====================================================
            // OR
            // ====================================================

            OP_OR: begin

                temp_ap.lor = 1'b1;
                temp_ap.zbb = 1'b0;

            end


            // ====================================================
            // ORN
            // ====================================================

            OP_ORN: begin

                temp_ap.lor = 1'b1;
                temp_ap.zbb = 1'b1;

            end


            // ====================================================
            // XOR
            // ====================================================

            OP_XOR: begin

                temp_ap.lxor = 1'b1;
                temp_ap.zbb  = 1'b0;

            end


            // ====================================================
            // XNOR
            // ====================================================

            OP_XNOR: begin

                temp_ap.lxor = 1'b1;
                temp_ap.zbb  = 1'b1;

            end


            // ====================================================
            // SRL
            // ====================================================

            OP_SRL: begin

                temp_ap.srl = 1'b1;

            end


            // ====================================================
            // SRA
            // ====================================================

            OP_SRA: begin

                temp_ap.sra = 1'b1;

            end


            // ====================================================
            // ROR
            // ====================================================

            OP_ROR: begin

                temp_ap.ror = 1'b1;

            end


            // ====================================================
            // BINV
            // ====================================================

            OP_BINV: begin

                temp_ap.binv = 1'b1;

            end


            // ====================================================
            // SH2ADD
            // ====================================================
            //
            // SH2ADD is legal only when ZBA is enabled.
            // ====================================================

            OP_SH2ADD: begin

                temp_ap.sh2add = 1'b1;
                temp_ap.zba    = 1'b1;

            end


            // ====================================================
            // SUB
            // ====================================================

            OP_SUB: begin

                temp_ap.sub = 1'b1;

            end


            // ====================================================
            // SLT
            // ====================================================
            //
            // According to the current BMU control behavior:
            //
            //      slt    = 1
            //      sub    = 1
            //      unsign = 0
            //
            // ====================================================

            OP_SLT: begin

                temp_ap.slt    = 1'b1;
                temp_ap.sub    = 1'b1;
                temp_ap.unsign = 1'b0;

            end


            // ====================================================
            // SLTU
            // ====================================================

            OP_SLTU: begin

                temp_ap.slt    = 1'b1;
                temp_ap.sub    = 1'b1;
                temp_ap.unsign = 1'b1;

            end


            // ====================================================
            // CTZ
            // ====================================================

            OP_CTZ: begin

                temp_ap.ctz = 1'b1;

            end


            // ====================================================
            // CPOP
            // ====================================================

            OP_CPOP: begin

                temp_ap.cpop = 1'b1;

            end


            // ====================================================
            // SEXT.B
            // ====================================================

            OP_SEXTB: begin

                temp_ap.siext_b = 1'b1;

            end


                        // ====================================================
            // MAX
            // ====================================================
            //
            // MAX uses the comparison/subtraction datapath.
            //
            // Therefore both:
            //
            //      max = 1
            //      sub = 1
            //
            // must be asserted.
            //
            // ====================================================

            OP_MAX: begin

                temp_ap.max = 1'b1;
                temp_ap.sub = 1'b1;

            end


            // ====================================================
            // PACK
            // ====================================================

            OP_PACK: begin

                temp_ap.pack = 1'b1;

            end


            // ====================================================
            // GREV
            // ====================================================

            OP_GREV: begin

                temp_ap.grev = 1'b1;

            end


            // ====================================================
            // DEFAULT
            // ====================================================

            default: begin

                temp_ap = '0;

            end

        endcase


        return temp_ap;

    endfunction


    // ============================================================
    // BODY
    // ============================================================
    //
    // Generate 100 legal constrained-random BMU transactions.
    //
    // Every iteration:
    //
    //   randomize operation + operands
    //              ↓
    //   create sequence item through factory
    //              ↓
    //   convert operation into AP controls
    //              ↓
    //   send transaction to sequencer / driver
    //
    // ============================================================

    virtual task body();

        bmu_sequence_item req;


        `uvm_info(
            "RAND_SEQ",
            "Starting BMU constrained-random sequence: 100 transactions",
            UVM_LOW
        )


        repeat (100) begin


            // ====================================================
            // RANDOMIZE
            // ====================================================

            if (!this.randomize()) begin

                `uvm_fatal(
                    "RAND_SEQ",
                    "Randomization failed in bmu_random_sequence"
                )

            end


            // ====================================================
            // CREATE TRANSACTION THROUGH UVM FACTORY
            // ====================================================

            req =
                bmu_sequence_item::type_id::create("req");


            // ====================================================
            // START ITEM
            // ====================================================

            start_item(req);


            // ====================================================
            // COMMON CONTROL SIGNALS
            // ====================================================

            req.rst_l         = 1'b1;

            req.scan_mode     = 1'b0;

            req.valid_in      = 1'b1;


            // csr_ren_in must remain zero for legal normal
            // operation traffic.
            req.csr_ren_in    = 1'b0;

            req.csr_rddata_in = 32'h0000_0000;


            // ====================================================
            // RANDOM OPERANDS
            // ====================================================

            req.a_in = rand_a;

            req.b_in = rand_b;


            // ====================================================
            // BUILD LEGAL AP CONTROL
            // ====================================================

            req.ap = build_ap(rand_op);


            // ====================================================
            // SEND ITEM
            // ====================================================

            finish_item(req);


            // Debug information.
            // UVM_HIGH means it will normally stay hidden unless
            // a higher verbosity is requested.
            `uvm_info(
                "RAND_SEQ",
                $sformatf(
                    "Random transaction: OP=%s A=%08h B=%08h",
                    rand_op.name(),
                    rand_a,
                    rand_b
                ),
                UVM_HIGH
            )

        end


        `uvm_info(
            "RAND_SEQ",
            "Completed BMU constrained-random sequence",
            UVM_LOW
        )


    endtask


endclass