`timescale 1ns / 1ps

/*
Modular adder/subtractor using 2's complement:
If subtract == 0: out = (in_a + in_b) mod in_m
If subtract == 1: out = (in_a - in_b) mod in_m

TIP! You can assume that in_a and in_b are smaller than in_m
-> in_a mod in_m = in_a
-> in_b mod in_m = in_b

-> in_a + in_b mod in_m = in_a + in_b if in_a + in_b > in_m else in_a + in_b mod in_m = in_a + in_b - in_m

-> in_a - in_b mod in_m = in_a - in_b + in_m if in_a - in_b < 0 else in_a - in_b mod in_m = in_a - in_b

2's complement:
  {carry_out, sum} = in_a + in_b + carry_in
  {carry_out, sum} = in_a + ~in_b + 1 and carry_out = carry_out xor 1

Why not use carry_out of addition? 
    a+b is max 2m-2 -> carry out of a+b-m is 0 -> select modulo operation
    a+b < m -> carry out of a+b-m is 1 -> select normal operation
        
    same reasoning for subtraction
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
    output wire         done
); 
    // intermediate signals of adders
    wire [384:0] res_adder1;
    wire [384:0] res_adder2;
   
    wire cout_adder1;
    wire cout_adder2;
    
    wire done_adder1;
    wire done_adder2;

    // intermediate wires
    wire [381:0] res;
    wire [380:0] out;

    // first 384 bit adder 

    adder adder1 (
        .clk    (clk    ),
        .resetn (resetn ),
        .start  (start  ),
        .subtract (subtract),
        .in_a   ({{3{in_a[380]}}, in_a}  ),
        .in_b   ({{3{in_b[380]}}, in_b}  ),
        .result (res_adder1),
        .done   (done_adder1   )
    );

    // wiring
    assign res = res_adder1[381:0];
    assign cout_adder1 = res_adder1[384]; // carry out of addition or subtraction

    // second 384 bit adder
    adder adder2 (
        .clk    (clk    ),
        .resetn (resetn ),
        .start  (done_adder1), // start when first adder is done
        .subtract (~subtract), // if first adder did addition, second does subtraction and vice versa
        .in_a   ({2'b0, res}),
        .in_b   ({3'b0, in_m}),
        .result (res_adder2),
        .done   (done_adder2   )
    );

    // wiring
    assign cout_adder2 = res_adder2[384]; // carry out of addition or subtraction
    assign out = res_adder2[380:0];
    assign done = done_adder2; // since rest is combinatorial logic, done when second adder is done

    // Res buffer because adder takes 1 clock cycle

    reg [380:0] res_buf;
    reg         cout_buf;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            res_buf <= 0;
            cout_buf <= 0;
        end else begin
            if (done_adder1) begin
                res_buf <= res;
                cout_buf <= cout_adder1;
            end else begin
                res_buf <= res_buf;
                cout_buf <= cout_buf;
            end
        end
    end

    // Final result selection
    wire [380:0] result_w;
    assign result_w = subtract ? (cout_buf ? out : res_buf) : (cout_adder2 ? res_buf : out);
    always @(*) begin
        result <= result_w;
    end

endmodule
