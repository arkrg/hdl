// module adder #(
//     parameter WIDTH_BIT = 32
// )(
//     input logic  [WIDTH_BIT-1:0] a,
//     input logic  [WIDTH_BIT-1:0] b,
//     output logic [WIDTH_BIT-1:0] sum,
//     output logic                 carry
// );
//
//     assign {carry, sum} = a + b;
//
// endmodule

module adder #(
)(
    adder_if aif 
);

    assign {aif.carry, aif.sum} = aif.a + aif.b;

endmodule
