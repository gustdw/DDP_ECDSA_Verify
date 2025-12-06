module pipelined_adder(
    input  wire         clk,
    input  wire         start,
    input  wire         Cin,
    input  wire [383:0] A,
    input  wire [383:0] B,
    output wire [384:0] C,
    output wire         done
    );

    reg [383:0] A_reg, B_reg, out_reg;
    reg         Cin_reg, start_reg, start_buf, start_buf2, done_reg;

    wire cout_adder;
    wire [127:0] adder_out;

    always @ (posedge clk) begin
        if (start) begin 
            A_reg <= A;
            B_reg <= B;
            Cin_reg <= Cin;
        end else begin
            A_reg <= {128'b0, A_reg[383:128]};
            B_reg <= {128'b0, B_reg[383:128]};
            Cin_reg <= cout_adder;
        end
    end

    always @ (posedge clk) begin
        start_reg <= start;
        start_buf <= start_reg;
        start_buf2 <= start_buf;
        done_reg <= start_buf2;
        
    end

    always @ (posedge clk) begin
        out_reg <= {adder_out, out_reg[383:128]};
    end

    assign {cout_adder, adder_out} = A_reg[127:0] + B_reg[127:0] + Cin_reg;
    assign done = done_reg;
    assign C = {Cin_reg, out_reg};



endmodule