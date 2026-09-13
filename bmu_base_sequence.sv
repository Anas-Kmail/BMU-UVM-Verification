class bmu_base_sequence
    extends uvm_sequence #(bmu_sequence_item);

    `uvm_object_utils(bmu_base_sequence)


    function new(string name = "bmu_base_sequence");

        super.new(name);

    endfunction


    virtual task body();

        // Base sequence does not generate stimulus.
        // Derived sequences will override this task.

    endtask

endclass