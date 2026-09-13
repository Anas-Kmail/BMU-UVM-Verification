class bmu_directed_sequence extends bmu_base_sequence;
    `uvm_object_utils(bmu_directed_sequence)

    bmu_sequence_item req;

    bmu_op_e op;

    logic signed [31:0] a_value;
    logic        [31:0] b_value;


    function new(string name = "bmu_directed_sequence");

        super.new(name);

        a_value = '0;
        b_value = '0;

    endfunction


    task body();

        req = bmu_sequence_item::type_id::create("req");

        start_item(req);


        // -----------------------------------------
        // Common valid-operation defaults
        // -----------------------------------------

        req.rst_l          = 1'b1;
        req.scan_mode      = 1'b0;
        req.valid_in       = 1'b1;

        req.csr_ren_in     = 1'b0;
        req.csr_rddata_in  = '0;

        req.a_in           = a_value;
        req.b_in           = b_value;

        // VERY IMPORTANT:
        // clear every control signal first
        req.ap             = '0;


        // -----------------------------------------
        // Select operation
        // -----------------------------------------

        case (op)


            // =====================================
            // CSR WRITE
            // =====================================

            OP_CSR_WRITE_REG: begin

                req.ap.csr_write = 1'b1;
                req.ap.csr_imm   = 1'b0;

            end


            OP_CSR_WRITE_IMM: begin

                req.ap.csr_write = 1'b1;
                req.ap.csr_imm   = 1'b1;

            end


            // =====================================
            // LOGICAL
            // =====================================

            OP_OR: begin

                req.ap.lor = 1'b1;
                req.ap.zbb = 1'b0;

            end


            OP_ORN: begin

                req.ap.lor = 1'b1;
                req.ap.zbb = 1'b1;

            end


            OP_XOR: begin

                req.ap.lxor = 1'b1;
                req.ap.zbb  = 1'b0;

            end


            OP_XNOR: begin

                req.ap.lxor = 1'b1;
                req.ap.zbb  = 1'b1;

            end


            // =====================================
            // SHIFT / MASK
            // =====================================

            OP_SRL: begin

                req.ap.srl = 1'b1;

            end


            OP_SRA: begin

                req.ap.sra = 1'b1;

            end


            OP_ROR: begin

                req.ap.ror = 1'b1;

            end


            OP_BINV: begin

                req.ap.binv = 1'b1;

            end


            OP_SH2ADD: begin

                req.ap.sh2add = 1'b1;
                req.ap.zba    = 1'b1;

            end


            // =====================================
            // ARITHMETIC
            // =====================================

            OP_SUB: begin

                req.ap.sub = 1'b1;

                // Spec requires ZBA = 0
                req.ap.zba = 1'b0;

            end


            // =====================================
            // SLT / SLTU
            // =====================================

            OP_SLT: begin

                req.ap.slt    = 1'b1;
                req.ap.sub    = 1'b1;
                req.ap.unsign = 1'b0;

            end


            OP_SLTU: begin

                req.ap.slt    = 1'b1;
                req.ap.sub    = 1'b1;
                req.ap.unsign = 1'b1;

            end


            // =====================================
            // BIT MANIPULATION
            // =====================================

            OP_CTZ: begin

                req.ap.ctz = 1'b1;

            end


            OP_CPOP: begin

                req.ap.cpop = 1'b1;

            end


            OP_SEXTB: begin

                req.ap.siext_b = 1'b1;

            end


            OP_MAX: begin

                req.ap.max = 1'b1;
                req.ap.sub = 1'b1;

            end


            OP_PACK: begin

                req.ap.pack = 1'b1;

            end


            OP_GREV: begin

                req.ap.grev = 1'b1;

                // Spec requires b_in[4:0] = 24
                req.b_in = {
                    b_value[31:5],
                    5'b11000
                };

            end


            default: begin

                `uvm_fatal(
                    "SEQ",
                    "Unsupported BMU operation"
                )

            end

        endcase


        finish_item(req);

    endtask

endclass