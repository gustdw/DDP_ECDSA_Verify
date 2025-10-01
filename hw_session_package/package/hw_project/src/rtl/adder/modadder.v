`timescale 1ns / 1ps

/*
Modular adder/subtractor using 2's complement:
- If subtract == 0: out = (in_a + in_b) mod in_m
- If subtract == 1: out = (in_a - in_b) mod in_m

TIP! You can assume that in_a and in_b are smaller than in_m
-> in_a mod in_m = in_a
-> in_b mod in_m = in_b
*/


module modadder(
    input  wire [380:0] in_a,
    input  wire [380:0] in_b,
    input  wire [380:0] in_m,
    input  wire         subtract,
    input  wire         start,
    input  wire         clk,
    input  wire         resetn,
    output reg [380:0] result,
    output reg         done
); 

//This is a normal adder you need a modular adder 
  always @(posedge clk) begin: addition
    result <= in_a + in_b;
  end
  
  always @(posedge clk) 
  begin
    done <= start;
  end

endmodule

