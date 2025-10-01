`timescale 1ns / 1ps

module adder(
  input  wire          clk,
  input  wire          resetn,
  input  wire          start,
  input  wire          subtract,
  input  wire [383:0] in_a,
  input  wire [383:0] in_b,
  output reg  [384:0] result,
  output reg          done    
  );

  wire [383:0] in_b_s;
  wire [384:0] result_w;
  wire done_w;
  assign in_b_s = subtract ? ((~in_b)+1) : in_b;
    pipelined_adder pa (
        .clk    (clk    ),
        .resetn (resetn ),
        .start  (start  ),
        .Cin    (1'b0),
        .A      (in_a  ),
        .B      (in_b_s  ),
        .C      (result_w),
        .done   (done_w   )
    );
    
    always @(*) begin
        result[383:0] <= result_w[383:0];
        result[384] <= result_w[384] ^ subtract;
        done <= done_w;
    end

endmodule
