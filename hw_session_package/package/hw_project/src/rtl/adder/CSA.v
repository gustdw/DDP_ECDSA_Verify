module carry_save_adder_384 (
    input  [383:0] A_sum,
    input  [383:0] A_carry,
    input  [383:0] B,
    output [383:0] C_sum,
    output [383:0] C_carry
);

    assign C_sum   = A_sum ^ A_carry ^ B;  // bitwise XOR
    assign C_carry = (A_sum & A_carry) | (A_sum & B) | (A_carry & B); // bitwise majority

    // canonical form is C_sum + (C_carry << 1)

endmodule