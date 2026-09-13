class bmu_stress_sequence extends bmu_random_sequence;

    `uvm_object_utils(bmu_stress_sequence)


    // ============================================================
    // Number of stress transactions
    //
    // Default = 2000
    //
    // Can be changed from command line using:
    //
    // +BMU_STRESS_N=5000
    //
    // ============================================================
    int unsigned num_transactions = 2000;


    // ============================================================
    // Constructor
    // ============================================================
    function new(string name = "bmu_stress_sequence");

        super.new(name);

    endfunction


    // ============================================================
    // Corner values for operand A
    // ============================================================
    function automatic logic signed [31:0]
        get_corner_a(input int unsigned selector);

        case (selector % 8)

            0: get_corner_a = 32'h0000_0000;
            1: get_corner_a = 32'h0000_0001;
            2: get_corner_a = 32'hFFFF_FFFF;
            3: get_corner_a = 32'h8000_0000;
            4: get_corner_a = 32'h7FFF_FFFF;
            5: get_corner_a = 32'hAAAA_AAAA;
            6: get_corner_a = 32'h5555_5555;
            7: get_corner_a = 32'h0000_0100;

            default:
                get_corner_a = 32'h0000_0000;

        endcase

    endfunction


    // ============================================================
    // Corner values for operand B
    // ============================================================
    function automatic logic [31:0]
        get_corner_b(input int unsigned selector);

        case (selector % 8)

            0: get_corner_b = 32'h0000_0000;
            1: get_corner_b = 32'h0000_0001;
            2: get_corner_b = 32'hFFFF_FFFF;
            3: get_corner_b = 32'h8000_0000;
            4: get_corner_b = 32'h7FFF_FFFF;
            5: get_corner_b = 32'hAAAA_AAAA;
            6: get_corner_b = 32'h5555_5555;
            7: get_corner_b = 32'h0000_001F;

            default:
                get_corner_b = 32'h0000_0000;

        endcase

    endfunction


    // ============================================================
    // Operations that use B[4:0] as a bit/shift amount
    // ============================================================
    function automatic bit
        is_shift_or_bit_index_op(input bmu_op_e op);

        case (op)

            OP_SRL,
            OP_SRA,
            OP_ROR,
            OP_BINV:
                return 1'b1;

            default:
                return 1'b0;

        endcase

    endfunction


    // ============================================================
    // Main Stress Sequence
    // ============================================================
    virtual task body();

        bmu_sequence_item req;

        logic signed [31:0] a_value;
        logic        [31:0] b_value;

        bit valid_value;
        bit do_reset;

        bmu_op_e selected_op;
        bmu_op_e previous_op;

        bit have_previous_op;

        int unsigned i;
        int unsigned choice;


        // --------------------------------------------------------
        // Allow transaction count to be changed from command line
        // --------------------------------------------------------
        void'(
            $value$plusargs(
                "BMU_STRESS_N=%d",
                num_transactions
            )
        );


        have_previous_op = 1'b0;


        `uvm_info(
            "STRESS_SEQ",
            $sformatf(
                "Starting BMU stress sequence: %0d transactions",
                num_transactions
            ),
            UVM_LOW
        )


        // ========================================================
        // Generate stress transactions
        // ========================================================
        for (i = 0; i < num_transactions; i++) begin


            // ----------------------------------------------------
            // Randomize legal operation + operands
            //
            // Inherited from bmu_random_sequence.
            // ----------------------------------------------------
            if (!this.randomize()) begin

                `uvm_fatal(
                    "STRESS_SEQ",
                    "Stress randomization failed"
                )

            end


            selected_op = rand_op;


            // ----------------------------------------------------
            // Approximately 15% of the time:
            //
            // repeat the previous operation.
            //
            // This stresses repeated execution of the same
            // datapath/control combination.
            // ----------------------------------------------------
            if (have_previous_op &&
                ($urandom_range(0, 99) < 15)) begin

                selected_op = previous_op;

            end


            // ----------------------------------------------------
            // Start with fully random operands
            // ----------------------------------------------------
            a_value = rand_a;
            b_value = rand_b;


            // ----------------------------------------------------
            // Approximately 30% probability:
            // replace A with a corner value
            // ----------------------------------------------------
            if ($urandom_range(0, 99) < 30) begin

                a_value =
                    get_corner_a(
                        $urandom_range(0, 7)
                    );

            end


            // ----------------------------------------------------
            // Approximately 30% probability:
            // replace B with a corner value
            // ----------------------------------------------------
            if ($urandom_range(0, 99) < 30) begin

                b_value =
                    get_corner_b(
                        $urandom_range(0, 7)
                    );

            end


            // ----------------------------------------------------
            // Stress shift / bit-index boundaries
            //
            // For SRL, SRA, ROR and BINV:
            //
            //     B[4:0] = 0
            //              1
            //              31
            //
            // These are important boundary values.
            // ----------------------------------------------------
            if (is_shift_or_bit_index_op(selected_op) &&
                ($urandom_range(0, 99) < 50)) begin

                choice = $urandom_range(0, 2);

                case (choice)

                    0:
                        b_value[4:0] = 5'd0;

                    1:
                        b_value[4:0] = 5'd1;

                    2:
                        b_value[4:0] = 5'd31;

                    default:
                        b_value[4:0] = 5'd0;

                endcase

            end


            // ----------------------------------------------------
            // Current verified GREV case is byte reverse.
            //
            // Therefore B[4:0] must remain 24.
            // ----------------------------------------------------
            if (selected_op == OP_GREV) begin

                b_value[4:0] = 5'd24;

            end


            // ----------------------------------------------------
            // About 2% of transactions perform synchronous reset
            // ----------------------------------------------------
            do_reset =
                ($urandom_range(0, 99) < 2);


            // ----------------------------------------------------
            // For normal transactions:
            //
            // valid_in = 1 roughly 90%
            // valid_in = 0 roughly 10%
            //
            // valid_in = 0 stresses HOLD behavior.
            // ----------------------------------------------------
            valid_value =
                ($urandom_range(0, 99) < 90);


            // ====================================================
            // Create transaction
            // ====================================================
            req =
                bmu_sequence_item::type_id::create(
                    $sformatf("stress_req_%0d", i)
                );


            start_item(req);


            // ====================================================
            // RESET transaction
            // ====================================================
            if (do_reset) begin

                req.rst_l         = 1'b0;
                req.scan_mode     = 1'b0;

                req.valid_in      = 1'b0;

                req.csr_ren_in    = 1'b0;
                req.csr_rddata_in = '0;

                req.a_in          = '0;
                req.b_in          = '0;

                req.ap            = '0;

            end


            // ====================================================
            // Normal legal transaction
            // ====================================================
            else begin

                req.rst_l         = 1'b1;
                req.scan_mode     = 1'b0;

                req.valid_in      = valid_value;

                req.csr_ren_in    = 1'b0;
                req.csr_rddata_in = '0;

                req.a_in          = a_value;
                req.b_in          = b_value;

                req.ap =
                    build_ap(selected_op);

            end


            finish_item(req);


            // ----------------------------------------------------
            // Remember previous legal operation
            // ----------------------------------------------------
            if (!do_reset) begin

                previous_op      = selected_op;
                have_previous_op = 1'b1;

            end


            // ----------------------------------------------------
            // Optional debug print
            //
            // UVM_HIGH means it normally will not flood terminal.
            // ----------------------------------------------------
            `uvm_info(
                "STRESS_SEQ",
                $sformatf(
                    "Txn=%0d Op=%s Reset=%0b Valid=%0b A=%08h B=%08h",
                    i,
                    selected_op.name(),
                    do_reset,
                    valid_value,
                    a_value,
                    b_value
                ),
                UVM_HIGH
            )

        end


        `uvm_info(
            "STRESS_SEQ",
            $sformatf(
                "Completed BMU stress sequence: %0d transactions",
                num_transactions
            ),
            UVM_LOW
        )

    endtask


endclass