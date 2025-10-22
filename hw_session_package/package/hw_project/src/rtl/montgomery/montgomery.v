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

  // Controller
  // State encoding (8 states)

    localparam S0 = 3'b000;
    localparam S1 = 3'b001;
    localparam S2 = 3'b010;
    localparam S3 = 3'b011;
    localparam S4 = 3'b100;
    localparam S5 = 3'b101;
   

    reg [2:0] state, next_state;
    reg [8:0] count; // counter for 381 bits
    reg done;

    reg [383:0] C;
    reg [380:0] A_reg, B_reg, M_reg;
    reg [381:0] BM_reg;
    reg [384:0] M_neg_reg;


    // Control signals
    reg increment, reset_count;
    reg subtract;
    reg select_in;
    reg comp_BM;
    reg [1:0] select_C; // 00 -> 0, 01 -> C, 10 -> adder output (shifted), 11 -> output adder (no shift)


    // Sequential logic for state transition
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state <= S0;
        end else begin
            state <= next_state;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        case (state)
            S0: begin
                if (start) begin
                    next_state = S5;
                end else begin
                    next_state = S0;
                end
            end
            S5: begin
                next_state = S1;
                end
            S1: begin
                if (count == 9'd380) begin
                    next_state = S2;
                end else begin
                    next_state = S1;
                end
            end
            S2: begin
                if (adder_out[384] == 1'b1) begin
                    next_state = S3;
                end else begin
                    next_state = S4;
                end
            end
            S3: begin
                next_state = S2;
            end
            S4: begin
                next_state = S0;
            end
            default: begin
                next_state = S0;
            end
        endcase
    end


    // Control signal logic
    always @(*) begin
        case (state)
            S0: begin
                select_in = 1'b1;
                comp_BM = 1'b0;
                done = 1'b0;
                increment = 1'b0;
                reset_count = 1'b1;
                subtract = 1'b0;
                select_C = 2'b00;
            end
            S5: begin
                select_in = 1'b1;
                comp_BM = 1'b1;
                done = 1'b0;
                increment = 1'b0;
                reset_count = 1'b0;
                subtract = 1'b0;
                select_C = 2'b00;
            end
                
            S1: begin
                select_in = 1'b0;
                comp_BM = 1'b0;
                done = 1'b0;
                increment = 1'b1;
                reset_count = 1'b0;
                subtract = 1'b0;
                select_C = 2'b10;
            end
            S2: begin
                select_in = 1'b0;
                comp_BM = 1'b0;
                done = 1'b0;
                increment = 1'b0;
                reset_count = 1'b0;
                subtract = 1'b1;
                select_C = 2'b01;
            end
            S3: begin
                select_in = 1'b0;
                comp_BM = 1'b0;
                done = 1'b0;
                increment = 1'b0;
                reset_count = 1'b0;
                subtract = 1'b1;
                select_C = 2'b11;
            end
            S4: begin
                select_in = 1'b0;
                comp_BM = 1'b0;
                done = 1'b1;
                increment = 1'b0;
                reset_count = 1'b0;
                subtract = 1'b0;
                select_C = 2'b01;
            end
            default: begin
                select_in = 1'b0;
                comp_BM = 1'b0;
                done = 1'b0;
                increment = 1'b0;
                reset_count = 1'b0;
                subtract = 1'b0;
                select_C = 2'b00;
            end
        endcase
    end

    // Data path
    // Wires
    wire [384:0] adder_out;
    reg [383:0] C_next;
    reg [380:0] A_next;
    reg [380:0] B_next;
    reg [380:0] M_next;
    reg [383:0] M_neg_next;
    reg [383:0] adder_in_b, adder_in_a;
    reg [381:0] BM_reg_next;


reg [383:0] add_a, add_b;

always @(*) begin
    casez ({comp_BM, A_reg[0], subtract, C[0]})
        4'b1???: begin
            add_a = {3'b0, M_reg};
            add_b = {3'b0, B_reg};
        end
        4'b01??: begin
            add_a = C;
            add_b = C[0] ^ B_reg[0] ? {2'b0, BM_reg} : {3'b0, B_reg};
        end
        4'b001?: begin
            add_a = C;
            add_b = M_neg_reg;
        end
        4'b0001: begin
            add_a = C;
            add_b = {3'b0, M_reg};
        end
        default: begin
            add_a = C;
            add_b = 384'b0;
        end
    endcase
end

assign adder_out = add_a + add_b;


    // Mux for inputs M and B
    always @(*) begin
        if (select_in) begin
            B_next = in_b;
            M_next = in_m;
            M_neg_next = - {3'b0, in_m};
        end else begin
            B_next = B_reg;
            M_next = M_reg;  
            M_neg_next = M_neg_reg;
        end
    end
    
    always @(*) begin
        if (comp_BM) begin
            BM_reg_next = adder_out[381:0];
        end else begin
            BM_reg_next = BM_reg;
        end
    end

    // Mux for inputs A
    always @(*) begin
        if (select_in) begin
            A_next = in_a;
        end else begin
            A_next = A_reg >> 1;
        end
    end

    // Mux for input C
    always @(*) begin
        case (select_C)
            2'b00: C_next = 383'b0;
            2'b01: C_next = C;
            2'b10: C_next = adder_out >> 1;
            2'b11: C_next = adder_out[383:0];
            default: C_next = 383'b0;
        endcase
    end


    // Registers
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            A_reg <= 381'b0;
            B_reg <= 381'b0;
            M_reg <= 381'b0;
            C <= 383'b0;
//            BM_reg <= 382'b0;
//            M_neg_reg <= 384'b0;
        end else begin
            A_reg <= A_next;
            B_reg <= B_next;
            M_reg <= M_next;
            C <= C_next;
            BM_reg <= BM_reg_next;
            M_neg_reg <= M_neg_next;
        end
    end
    
    assign result = C[380:0];

    // Counter
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            count <= 9'd0;
        end else begin
            if (reset_count) begin
                count <= 9'd0;
            end else if (increment) begin
                count <= count + 9'd1;
            end else begin
                count <= count;
            end
        end
    end

endmodule