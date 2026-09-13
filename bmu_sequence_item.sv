class bmu_sequence_item extends uvm_sequence_item;

    `uvm_object_utils(bmu_sequence_item)

    logic rst_l;
    logic scan_mode;

    rand logic valid_in;

    rand logic csr_ren_in;
    rand logic [31:0] csr_rddata_in;

    rand logic signed [31:0] a_in;
    rand logic        [31:0] b_in;

    rand rtl_alu_pkt_t ap;

    logic [31:0] result_ff;
    logic        error;


    function new(string name = "bmu_sequence_item");

        super.new(name);

    endfunction

endclass