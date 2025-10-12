module single_stage_adder(
    input  wire         clk,
    input  wire         resetn,
    input  wire         start,
    input  wire         Cin,
    input  wire [383:0] A,
    input  wire [383:0] B,
    output wire [384:0] C,
    output wire         done);

    reg done_reg;
    reg [384:0] res_reg;
    always @(posedge clk, negedge resetn) begin
        if (~resetn) begin
            done_reg <= 1'b0;
            res_reg <= 385'b0;
        end else begin
            done_reg <= start; // combinational path, done is high when start is high
            res_reg <= A + B + Cin;
        end
    end
    assign done = done_reg;
    assign C = res_reg;
    
endmodule