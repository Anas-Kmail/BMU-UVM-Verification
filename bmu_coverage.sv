class bmu_coverage extends uvm_subscriber #(bmu_sequence_item);

    `uvm_component_utils(bmu_coverage)


    // ============================================================
    // Coverage operation types
    // ============================================================
    typedef enum int {

        COV_CSR_WRITE_REG,
        COV_CSR_WRITE_IMM,

        COV_OR,
        COV_ORN,

        COV_XOR,
        COV_XNOR,

        COV_SRL,
        COV_SRA,
        COV_ROR,

        COV_BINV,

        COV_SH2ADD,

        COV_SUB,
        COV_SLT,
        COV_SLTU,

        COV_CTZ,
        COV_CPOP,

        COV_SEXTB,

        COV_MAX,

        COV_PACK,

        COV_GREV,

        COV_IDLE,
        COV_INVALID,
        COV_UNKNOWN

    } bmu_cov_op_e;


    // ============================================================
    // Invalid transaction types
    // ============================================================
    typedef enum int {

        ERR_NONE,

        ERR_CSR_AP_CONFLICT,

        ERR_SH2ADD_NO_ZBA,

        ERR_SUB_WITH_ZBA,

        ERR_OR_XOR_CONFLICT,

        ERR_SRL_OR_CONFLICT,

        ERR_SRA_OR_CONFLICT,

        ERR_ROR_OR_CONFLICT,

        ERR_BINV_OR_CONFLICT,

        ERR_GREV_OR_CONFLICT

    } bmu_cov_error_e;


    // ============================================================
    // Variables sampled by covergroup
    // ============================================================
    bmu_cov_op_e    sampled_op;
    bmu_cov_error_e sampled_error_type;

    logic sampled_valid_in;
    logic sampled_error;
    logic sampled_rst_l;


    // ============================================================
    // COVERGROUP
    // ============================================================
    covergroup bmu_cg;

        option.per_instance = 1;


        // ========================================================
        // Operation Coverage
        //
        // We want every supported operation to be exercised.
        // ========================================================
        cp_operation : coverpoint sampled_op {

            bins csr_write_reg = {COV_CSR_WRITE_REG};
            bins csr_write_imm = {COV_CSR_WRITE_IMM};

            bins or_op         = {COV_OR};
            bins orn_op        = {COV_ORN};

            bins xor_op        = {COV_XOR};
            bins xnor_op       = {COV_XNOR};

            bins srl_op        = {COV_SRL};
            bins sra_op        = {COV_SRA};
            bins ror_op        = {COV_ROR};

            bins binv_op       = {COV_BINV};

            bins sh2add_op     = {COV_SH2ADD};

            bins sub_op        = {COV_SUB};
            bins slt_op        = {COV_SLT};
            bins sltu_op       = {COV_SLTU};

            bins ctz_op        = {COV_CTZ};
            bins cpop_op       = {COV_CPOP};

            bins sextb_op      = {COV_SEXTB};

            bins max_op        = {COV_MAX};

            bins pack_op       = {COV_PACK};

            bins grev_op       = {COV_GREV};

            bins idle          = {COV_IDLE};

            bins invalid       = {COV_INVALID};

            illegal_bins unknown =
                {COV_UNKNOWN};
        }


        // ========================================================
        // valid_in Coverage
        //
        // Important because we now explicitly verify:
        // valid_in = 0 → result_ff holds
        // ========================================================
        cp_valid_in : coverpoint sampled_valid_in {

            bins valid_zero = {1'b0};
            bins valid_one  = {1'b1};

        }


        // ========================================================
        // DUT error output coverage
        // ========================================================
        cp_error : coverpoint sampled_error {

            bins no_error = {1'b0};
            bins error    = {1'b1};

        }


        // ========================================================
        // Reset Coverage
        // ========================================================
        cp_reset : coverpoint sampled_rst_l {

            bins reset_active   = {1'b0};
            bins reset_inactive = {1'b1};

        }


        // ========================================================
        // Invalid Scenario Coverage
        //
        // Each important invalid scenario should be exercised.
        // ========================================================
        cp_error_type : coverpoint sampled_error_type {

            bins csr_ap_conflict =
                {ERR_CSR_AP_CONFLICT};

            bins sh2add_no_zba =
                {ERR_SH2ADD_NO_ZBA};

            bins sub_with_zba =
                {ERR_SUB_WITH_ZBA};

            bins or_xor_conflict =
                {ERR_OR_XOR_CONFLICT};

            bins srl_or_conflict =
                {ERR_SRL_OR_CONFLICT};

            bins sra_or_conflict =
                {ERR_SRA_OR_CONFLICT};

            bins ror_or_conflict =
                {ERR_ROR_OR_CONFLICT};

            bins binv_or_conflict =
                {ERR_BINV_OR_CONFLICT};

            bins grev_or_conflict =
                {ERR_GREV_OR_CONFLICT};

            ignore_bins no_error =
                {ERR_NONE};
        }


        // ========================================================
        // Cross:
        // valid_in vs error
        //
        // Especially important:
        //
        // valid_in = 0 AND error = 1
        //
        // This proves that we exercised the clarification:
        // error is independent of valid_in.
        // ========================================================
        cross_valid_error :
            cross cp_valid_in, cp_error;


    endgroup


    // ============================================================
    // Constructor
    // ============================================================
    function new(
        string name = "bmu_coverage",
        uvm_component parent = null
    );

        super.new(name, parent);

        bmu_cg = new();

    endfunction


    // ============================================================
    // Detect Invalid Transaction Type
    // ============================================================
    function automatic bmu_cov_error_e
        get_error_type(
            input bmu_sequence_item tr
        );


        // --------------------------------------------------------
        // CSR read + AP control
        // --------------------------------------------------------
        if ((tr.csr_ren_in == 1'b1) &&
            (tr.ap != '0)) begin

            return ERR_CSR_AP_CONFLICT;

        end


        // --------------------------------------------------------
        // SH2ADD without ZBA
        // --------------------------------------------------------
        if ((tr.ap.sh2add == 1'b1) &&
            (tr.ap.zba    == 1'b0)) begin

            return ERR_SH2ADD_NO_ZBA;

        end


        // --------------------------------------------------------
        // SUB with ZBA
        // --------------------------------------------------------
        if ((tr.ap.sub == 1'b1) &&
            (tr.ap.zba == 1'b1)) begin

            return ERR_SUB_WITH_ZBA;

        end


        // --------------------------------------------------------
        // OR + XOR
        // --------------------------------------------------------
        if ((tr.ap.lor == 1'b1) &&
            (tr.ap.lxor == 1'b1)) begin

            return ERR_OR_XOR_CONFLICT;

        end


        // --------------------------------------------------------
        // SRL + OR
        // --------------------------------------------------------
        if ((tr.ap.srl == 1'b1) &&
            (tr.ap.lor == 1'b1)) begin

            return ERR_SRL_OR_CONFLICT;

        end


        // --------------------------------------------------------
        // SRA + OR
        // --------------------------------------------------------
        if ((tr.ap.sra == 1'b1) &&
            (tr.ap.lor == 1'b1)) begin

            return ERR_SRA_OR_CONFLICT;

        end


        // --------------------------------------------------------
        // ROR + OR
        // --------------------------------------------------------
        if ((tr.ap.ror == 1'b1) &&
            (tr.ap.lor == 1'b1)) begin

            return ERR_ROR_OR_CONFLICT;

        end


        // --------------------------------------------------------
        // BINV + OR
        // --------------------------------------------------------
        if ((tr.ap.binv == 1'b1) &&
            (tr.ap.lor == 1'b1)) begin

            return ERR_BINV_OR_CONFLICT;

        end


        // --------------------------------------------------------
        // GREV + OR
        // --------------------------------------------------------
        if ((tr.ap.grev == 1'b1) &&
            (tr.ap.lor == 1'b1)) begin

            return ERR_GREV_OR_CONFLICT;

        end


        return ERR_NONE;

    endfunction


    // ============================================================
    // Decode BMU Operation
    // ============================================================
    function automatic bmu_cov_op_e
        decode_operation(
            input bmu_sequence_item tr
        );

        bmu_cov_error_e error_type;


        error_type =
            get_error_type(tr);


        // --------------------------------------------------------
        // Reset
        //
        // We classify reset as idle for operation coverage.
        // Reset itself is separately covered by cp_reset.
        // --------------------------------------------------------
        if (tr.rst_l == 1'b0)

            return COV_IDLE;


        // --------------------------------------------------------
        // Invalid transaction
        // --------------------------------------------------------
        if (error_type != ERR_NONE)

            return COV_INVALID;


        // --------------------------------------------------------
        // Idle / Hold
        // --------------------------------------------------------
        if (tr.valid_in == 1'b0)

            return COV_IDLE;


        // --------------------------------------------------------
        // CSR WRITE
        // --------------------------------------------------------
        if (tr.ap.csr_write) begin

            if (tr.ap.csr_imm)

                return COV_CSR_WRITE_IMM;

            else

                return COV_CSR_WRITE_REG;

        end


        // --------------------------------------------------------
        // OR / ORN
        // --------------------------------------------------------
        if (tr.ap.lor) begin

            if (tr.ap.zbb)

                return COV_ORN;

            else

                return COV_OR;

        end


        // --------------------------------------------------------
        // XOR / XNOR
        // --------------------------------------------------------
        if (tr.ap.lxor) begin

            if (tr.ap.zbb)

                return COV_XNOR;

            else

                return COV_XOR;

        end


        // --------------------------------------------------------
        // SRL
        // --------------------------------------------------------
        if (tr.ap.srl)

            return COV_SRL;


        // --------------------------------------------------------
        // SRA
        // --------------------------------------------------------
        if (tr.ap.sra)

            return COV_SRA;


        // --------------------------------------------------------
        // ROR
        // --------------------------------------------------------
        if (tr.ap.ror)

            return COV_ROR;


        // --------------------------------------------------------
        // BINV
        // --------------------------------------------------------
        if (tr.ap.binv)

            return COV_BINV;


        // --------------------------------------------------------
        // SH2ADD
        // --------------------------------------------------------
        if (tr.ap.sh2add &&
            tr.ap.zba)

            return COV_SH2ADD;


        // --------------------------------------------------------
        // SLT / SLTU
        //
        // Must be checked before SUB.
        // --------------------------------------------------------
        if (tr.ap.slt &&
            tr.ap.sub) begin

            if (tr.ap.unsign)

                return COV_SLTU;

            else

                return COV_SLT;

        end


        // --------------------------------------------------------
        // MAX
        //
        // Must be checked before normal SUB.
        // --------------------------------------------------------
        if (tr.ap.max &&
            tr.ap.sub)

            return COV_MAX;


        // --------------------------------------------------------
        // SUB
        // --------------------------------------------------------
        if (tr.ap.sub &&
            !tr.ap.zba)

            return COV_SUB;


        // --------------------------------------------------------
        // CTZ
        // --------------------------------------------------------
        if (tr.ap.ctz)

            return COV_CTZ;


        // --------------------------------------------------------
        // CPOP
        // --------------------------------------------------------
        if (tr.ap.cpop)

            return COV_CPOP;


        // --------------------------------------------------------
        // SEXT.B
        // --------------------------------------------------------
        if (tr.ap.siext_b)

            return COV_SEXTB;


        // --------------------------------------------------------
        // PACK
        // --------------------------------------------------------
        if (tr.ap.pack)

            return COV_PACK;


        // --------------------------------------------------------
        // GREV
        // --------------------------------------------------------
        if (tr.ap.grev)

            return COV_GREV;


        return COV_UNKNOWN;

    endfunction


    // ============================================================
    // WRITE
    //
    // Called automatically whenever monitor sends a transaction
    // through its analysis port.
    // ============================================================
  virtual function void write(
    bmu_sequence_item t
);

    sampled_op =
        decode_operation(t);

    sampled_error_type =
        get_error_type(t);

    sampled_valid_in =
        t.valid_in;

    sampled_error =
        t.error;

    sampled_rst_l =
        t.rst_l;


    // Sample all coverpoints
    bmu_cg.sample();

endfunction


    // ============================================================
    // REPORT PHASE
    // ============================================================
    function void report_phase(
        uvm_phase phase
    );

        real coverage_percentage;

        super.report_phase(phase);


        coverage_percentage =
            bmu_cg.get_inst_coverage();


        `uvm_info(
            "COV",
            $sformatf(
                "BMU Functional Coverage = %0.2f%%",
                coverage_percentage
            ),
            UVM_LOW
        )

    endfunction


endclass