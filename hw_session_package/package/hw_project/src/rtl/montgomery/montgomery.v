`timescale 1ns / 1ps

module montgomery(
  input           clk,
  input           resetn,
  input           start,
  input  [380:0] in_a,
  input  [380:0] in_b,
  input  [380:0] in_m,
  output [380:0] result,
  output          done
    );

  // Student tasks:
  // 1. Instantiate an Adder (tip: the testbenches for the adder also instantiated an adder)
  // 2. Use the Adder to implement the Montgomery multiplier in hardware.
  // 3. Use tb_montgomery.v to simulate your design.

  // Dear Students: This always block was added to ensure the tool doesn't
  // trim away the montgomery module. Feel free to remove this block.

  reg [380:0] r_result;
  always @(posedge(clk))
    r_result <= {381{1'b1}};

  assign result = r_result;

  assign done = 1'b1;

endmodule


