class bmu_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(bmu_scoreboard)


    // ============================================================
    // Analysis implementation
    // ============================================================
    uvm_analysis_imp #(
        bmu_sequence_item,
        bmu_scoreboard
    ) analysis_imp;


    // ============================================================
    // Scoreboard state
    // ============================================================

    // What the reference model expected to be written
    logic [31:0] previous_expected_result;

    // What was ACTUALLY stored in DUT result_ff
    //
    // Important for checking HOLD behavior when valid_in = 0.
    logic [31:0] previous_actual_result;


    // ============================================================
    // Constructor
    // ============================================================
    function new(
        string name = "bmu_scoreboard",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // ============================================================
    // Build Phase
    // ============================================================
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        analysis_imp = new(
            "analysis_imp",
            this
        );

        previous_expected_result = 32'h0000_0000;
        previous_actual_result   = 32'h0000_0000;

    endfunction


    // ============================================================
    // CTZ Reference Function
    // ============================================================
    function automatic [31:0]
        calc_ctz(input logic [31:0] value);

        int i;

        // According to clarification:
        // CTZ(0) = 32
        if (value == 32'b0)
            return 32;

        for (i = 0; i < 32; i++) begin

            if (value[i])
                return i;

        end

        return 32;

    endfunction


    // ============================================================
    // CPOP Reference Function
    // ============================================================
    function automatic logic [31:0]
        calc_cpop(input logic [31:0] value);

        integer i;

        calc_cpop = 0;

        for (i = 0; i < 32; i = i + 1) begin

            if (value[i])
                calc_cpop = calc_cpop + 1;

        end

    endfunction


    // ============================================================
    // ROR Reference Function
    // ============================================================
    function automatic logic [31:0]
        calc_ror(
            input logic [31:0] value,
            input logic [4:0]  shamt
        );

        if (shamt == 0)

            calc_ror = value;

        else

            calc_ror =
                (value >> shamt) |
                (value << (32 - shamt));

    endfunction


    // ============================================================
    // INVALID TRANSACTION DETECTION
    // ============================================================
    function automatic bit
        is_invalid_transaction(
            input bmu_sequence_item tr
        );

        is_invalid_transaction = 1'b0;


        // --------------------------------------------------------
        // CSR read active together with any AP control
        // --------------------------------------------------------
        if ((tr.csr_ren_in == 1'b1) &&
            (tr.ap != '0)) begin

            return 1'b1;

        end


        // --------------------------------------------------------
        // SH2ADD requires ZBA
        // --------------------------------------------------------
        if ((tr.ap.sh2add == 1'b1) &&
            (tr.ap.zba    == 1'b0)) begin

            return 1'b1;

        end


        // --------------------------------------------------------
        // SUB must not be combined with ZBA
        // --------------------------------------------------------
        if ((tr.ap.sub == 1'b1) &&
            (tr.ap.zba == 1'b1)) begin

            return 1'b1;

        end


        // --------------------------------------------------------
        // OR / XOR conflict
        // --------------------------------------------------------
        if ((tr.ap.lor  == 1'b1) &&
            (tr.ap.lxor == 1'b1)) begin

            return 1'b1;

        end


        // --------------------------------------------------------
        // SRL + OR conflict
        // --------------------------------------------------------
        if ((tr.ap.srl == 1'b1) &&
            (tr.ap.lor == 1'b1)) begin

            return 1'b1;

        end


        // --------------------------------------------------------
        // SRA + OR conflict
        // --------------------------------------------------------
        if ((tr.ap.sra == 1'b1) &&
            (tr.ap.lor == 1'b1)) begin

            return 1'b1;

        end


        // --------------------------------------------------------
        // ROR + OR conflict
        // --------------------------------------------------------
        if ((tr.ap.ror == 1'b1) &&
            (tr.ap.lor == 1'b1)) begin

            return 1'b1;

        end


        // --------------------------------------------------------
        // BINV + OR conflict
        // --------------------------------------------------------
        if ((tr.ap.binv == 1'b1) &&
            (tr.ap.lor  == 1'b1)) begin

            return 1'b1;

        end


        // --------------------------------------------------------
        // GREV + OR conflict
        // --------------------------------------------------------
        if ((tr.ap.grev == 1'b1) &&
            (tr.ap.lor  == 1'b1)) begin

            return 1'b1;

        end


        return 1'b0;

    endfunction


    // ============================================================
    // RECEIVE TRANSACTION FROM MONITOR
    // ============================================================
    function void write(bmu_sequence_item tr);

        logic [31:0] expected_result;
        logic [31:0] calculated_result;

        logic        expected_error;

        string       op_name;

        bit          recognized;


        // ========================================================
        // Defaults
        // ========================================================
        expected_result   = 32'h0000_0000;
        calculated_result = 32'h0000_0000;

        expected_error =
            is_invalid_transaction(tr);

        op_name   = "UNKNOWN";
        recognized = 1'b1;


        // ========================================================
        // RESET
        // ========================================================
        if (tr.rst_l == 1'b0) begin

            op_name = "RESET";

            expected_error = 1'b0;

            calculated_result =
                32'h0000_0000;

        end


        // ========================================================
        // INVALID TRANSACTION
        //
        // IMPORTANT:
        // Check invalid BEFORE checking valid_in.
        //
        // error is independent of valid_in.
        // ========================================================
        else if (expected_error) begin

            op_name = "INVALID";

            calculated_result =
                32'h0000_0000;

        end


        // ========================================================
        // IDLE / HOLD
        //
        // No valid operation is being accepted.
        //
        // This is NOT an unknown transaction.
        //
        // result_ff must hold its previous actual value.
        // error should remain 0 unless an invalid condition
        // was already detected above.
        // ========================================================
        else if (tr.valid_in == 1'b0) begin

            op_name = "IDLE/HOLD";

            expected_error = 1'b0;

            calculated_result =
                previous_actual_result;

        end


        // ========================================================
        // CSR WRITE
        // ========================================================
        else if (tr.ap.csr_write) begin

            op_name = "CSR_WRITE";

            if (tr.ap.csr_imm)

                calculated_result =
                    tr.b_in;

            else

                calculated_result =
                    tr.a_in;

        end


        // ========================================================
        // OR / ORN
        // ========================================================
        else if (tr.ap.lor) begin

            if (tr.ap.zbb) begin

                op_name = "ORN";

                calculated_result =
                    tr.a_in |
                    ~tr.b_in;

            end

            else begin

                op_name = "OR";

                calculated_result =
                    tr.a_in |
                    tr.b_in;

            end

        end


        // ========================================================
        // XOR / XNOR
        // ========================================================
        else if (tr.ap.lxor) begin

            if (tr.ap.zbb) begin

                op_name = "XNOR";

                calculated_result =
                    tr.a_in ^
                    ~tr.b_in;

            end

            else begin

                op_name = "XOR";

                calculated_result =
                    tr.a_in ^
                    tr.b_in;

            end

        end


        // ========================================================
        // SRL
        // ========================================================
        else if (tr.ap.srl) begin

            op_name = "SRL";

            calculated_result =
                $unsigned(tr.a_in)
                >> tr.b_in[4:0];

        end


        // ========================================================
        // SRA
        // ========================================================
        else if (tr.ap.sra) begin

            op_name = "SRA";

            calculated_result =
                $signed(tr.a_in)
                >>> tr.b_in[4:0];

        end


        // ========================================================
        // ROR
        // ========================================================
        else if (tr.ap.ror) begin

            op_name = "ROR";

            calculated_result =
                calc_ror(
                    tr.a_in,
                    tr.b_in[4:0]
                );

        end


        // ========================================================
        // BINV
        // ========================================================
        else if (tr.ap.binv) begin

            op_name = "BINV";

            calculated_result =
                tr.a_in ^
                (32'b1 << tr.b_in[4:0]);

        end


        // ========================================================
        // SH2ADD
        // ========================================================
        else if (tr.ap.sh2add &&
                 tr.ap.zba) begin

            op_name = "SH2ADD";

            calculated_result =
                (tr.a_in << 2) +
                tr.b_in;

        end


        // ========================================================
        // SLT / SLTU
        //
        // Must be before SUB because SLT requires ap.sub = 1.
        // ========================================================
        else if (tr.ap.slt &&
                 tr.ap.sub) begin

            if (tr.ap.unsign) begin

                op_name = "SLTU";

                calculated_result =
                    (
                        $unsigned(tr.a_in)
                        <
                        $unsigned(tr.b_in)
                    )
                    ? 32'd1
                    : 32'd0;

            end

            else begin

                op_name = "SLT";

                calculated_result =
                    (
                        $signed(tr.a_in)
                        <
                        $signed(tr.b_in)
                    )
                    ? 32'd1
                    : 32'd0;

            end

        end


        // ========================================================
        // MAX
        //
        // Must be before SUB because MAX also requires ap.sub = 1.
        // ========================================================
        else if (tr.ap.max &&
                 tr.ap.sub) begin

            op_name = "MAX";

            calculated_result =
                (
                    $signed(tr.a_in)
                    >
                    $signed(tr.b_in)
                )
                ? tr.a_in
                : tr.b_in;

        end


        // ========================================================
        // SUB
        // ========================================================
        else if (tr.ap.sub &&
                 !tr.ap.zba) begin

            op_name = "SUB";

            calculated_result =
                tr.a_in -
                tr.b_in;

        end


        // ========================================================
        // CTZ
        // ========================================================
        else if (tr.ap.ctz) begin

            op_name = "CTZ";

            calculated_result =
                calc_ctz(
                    tr.a_in
                );

        end


        // ========================================================
        // CPOP
        // ========================================================
        else if (tr.ap.cpop) begin

            op_name = "CPOP";

            calculated_result =
                calc_cpop(
                    tr.a_in
                );

        end


        // ========================================================
        // SEXT.B
        // ========================================================
        else if (tr.ap.siext_b) begin

            op_name = "SEXT.B";

            calculated_result = {
                {24{tr.a_in[7]}},
                tr.a_in[7:0]
            };

        end


        // ========================================================
        // PACK
        // ========================================================
        else if (tr.ap.pack) begin

            op_name = "PACK";

            calculated_result = {
                tr.b_in[15:0],
                tr.a_in[15:0]
            };

        end


        // ========================================================
        // GREV -- BYTE REVERSE
        // ========================================================
        else if (tr.ap.grev) begin

            op_name = "GREV";

            calculated_result = {
                tr.a_in[7:0],
                tr.a_in[15:8],
                tr.a_in[23:16],
                tr.a_in[31:24]
            };

        end


        // ========================================================
        // UNKNOWN VALID OPERATION
        //
        // valid_in = 1 but no supported operation was recognized.
        // ========================================================
        else begin

            recognized = 1'b0;

        end


            // ========================================================
        // Unknown transaction
        // ========================================================
        if (!recognized) begin

            `uvm_error(
                "SCB",
                $sformatf(
                    {"Unknown valid BMU operation observed\n",
                    "  valid_in   = %0b\n",
                    "  csr_ren_in = %0b\n",
                    "  A          = %08h\n",
                    "  B          = %08h\n",
                    "  AP         = %b"},
                    tr.valid_in,
                    tr.csr_ren_in,
                    tr.a_in,
                    tr.b_in,
                    tr.ap
                )
            )

            // Keep actual history synchronized
            previous_actual_result = tr.result_ff;

            return;

        end


        // ========================================================
        // RESULT_FF REFERENCE MODEL
        // ========================================================

        // Reset clears result_ff
        if (tr.rst_l == 1'b0) begin

            expected_result =
                32'h0000_0000;

        end


        // valid_in = 1:
        // DUT register accepts new calculated result
        else if (tr.valid_in == 1'b1) begin

            expected_result =
                calculated_result;

        end


        // valid_in = 0:
        // DUT must hold the value that was ACTUALLY stored before
        else begin

            expected_result =
                previous_actual_result;

        end


        // ========================================================
        // Compare Actual vs Expected
        // ========================================================
        if ((tr.result_ff !== expected_result) ||
            (tr.error     !== expected_error)) begin

            `uvm_error(
                "SCB",
                $sformatf(
                    "FAIL %-10s Valid=%0b A=%h B=%h Expected=%h Actual=%h ExpectedError=%0b ActualError=%0b",
                    op_name,
                    tr.valid_in,
                    tr.a_in,
                    tr.b_in,
                    expected_result,
                    tr.result_ff,
                    expected_error,
                    tr.error
                )
            )

        end

        else begin

            `uvm_info(
                "SCB",
                $sformatf(
                    "PASS %-10s Valid=%0b A=%h B=%h Expected=%h Actual=%h ExpectedError=%0b ActualError=%0b",
                    op_name,
                    tr.valid_in,
                    tr.a_in,
                    tr.b_in,
                    expected_result,
                    tr.result_ff,
                    expected_error,
                    tr.error
                ),
                UVM_LOW
            )

        end


        // ========================================================
        // UPDATE REFERENCE STATE
        // ========================================================

        // --------------------------------------------------------
        // Expected model state
        // --------------------------------------------------------
        if (tr.rst_l == 1'b0) begin

            previous_expected_result =
                32'h0000_0000;

        end

        else if (tr.valid_in == 1'b1) begin

            previous_expected_result =
                calculated_result;

        end

        // If valid_in = 0:
        // expected register state holds.


        // --------------------------------------------------------
        // Actual DUT state
        //
        // Always remember the current real result_ff.
        // This is what must be held on the next valid_in = 0 cycle.
        // --------------------------------------------------------
        previous_actual_result =
            tr.result_ff;

    endfunction


endclass