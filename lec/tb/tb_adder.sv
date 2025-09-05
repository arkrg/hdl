interface adder_if#(
    parameter WIDTH_BIT = 4
    );
    logic [WIDTH_BIT-1:0] a;
    logic [WIDTH_BIT-1:0] b;
    logic [WIDTH_BIT-1:0] sum;
    logic  carry;
endinterface

class transaction;
    // rand bit [WIDTH_BIT:0] a;
    // rand bit [WIDTH_BIT:0] b;
    rand bit [3:0] a;
    rand bit [3:0] b;
endclass : transaction 

class generator;
    virtual adder_if vif;

    transaction tr;

    function new(virtual adder_if adder_interf);
        this.vif = adder_interf;
        tr = new();
    endfunction

    task run(int count);
        repeat (count) begin
        tr.randomize();
        vif.a = tr.a;
        vif.b = tr.b;
        $display("input a:%d, b:%d", vif.a, vif.b);
        #10;
            
        end
    endtask

endclass : generator

module tb_adder();
    parameter WIDTH_BIT = 4;
    adder_if aif();
    generator gen;
    
    adder #(
    ) dut (
        aif
    );

    initial begin
        gen = new(aif);
        gen.run(100);
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars();
    end
endmodule


