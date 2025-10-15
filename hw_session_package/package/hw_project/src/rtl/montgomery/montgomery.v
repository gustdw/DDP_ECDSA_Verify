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
    localparam S6 = 3'b110;
    localparam S7 = 3'b111;

    reg [2:0] state, next_state;
    reg [8:0] count; // counter for 381 bits
    reg done;

    reg [383:0] C;
    reg [380:0] A_reg, B_reg, M_reg;


    // Control signals
    reg increment, reset_count;
    reg subtract;
    reg select_in_b_adder;
    reg select_in;
    reg shift_a;
    reg [1:0] select_shift; // 00 -> shift a, 01 -> shift C, 10 -> shift adder output
    reg [2:0] select_C; // 000 -> 0, 001 -> C, 010 -> C >> 1, 011 -> C+B or C-M, 100 -> C + M >> 1


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
                    next_state = S1;
                end else begin
                    next_state = S0;
                end
            end
            S1: begin
                if ((A_reg[0] ? adder_out[0] : C[0])) begin
                    next_state = S3;
                end else begin
                    next_state = S4;
                end
            end
            S3: begin
                if (count == 9'd380) begin
                    next_state = S5;
                end else begin
                    next_state = S1;
                end
            end
            S4: begin
                if (count == 9'd380) begin
                    next_state = S5;
                end else begin
                    next_state = S1;
                end
            end
            S5: begin
                if (C[384] == 1'b1) begin
                    next_state = S6;
                end else begin
                    next_state = S7;
                end
            end
            S6: begin
                next_state = S5;
            end
            S7: begin
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
                shift_a = 1'b0;
                done = 1'b0;
                increment = 1'b0;
                reset_count = 1'b1;
                select_in_b_adder = 1'b0;
                subtract = 1'b0;
                select_shift = 2'b00;
                select_C = 2'b000;
            end
            S1: begin
                if (A_reg[0] == 1'b1) begin
                    select_C = 3'b011; // select C + B
                end else begin
                    select_C = 3'b001; // select C
                end
                select_in = 1'b0;
                shift_a = 1'b1;
                done = 1'b0;
                increment = 1'b0;
                reset_count = 1'b0;
                select_in_b_adder = 1'b1; // select B
                subtract = 1'b0; // addition
                select_shift = 3'b00; // shift a
                
            end
//                S2: begin
//                    select_in = 1'b0;
//                    shift_a = 1'b0;
//                    done = 1'b0;
//                    increment = 1'b0;
//                    reset_count = 1'b0;
//                    select_in_b_adder = 1'bx;
//                    subtract = 1'b0;
//                    select_shift = 2'b00;
//                    select_C = 3'b001; // select C
//                end
            S3: begin
                select_in = 1'b0;
                shift_a = 1'b0;
                done = 1'b0;
                increment = 1'b1;
                reset_count = 1'b0;
                select_in_b_adder = 1'b0; // select M
                subtract = 1'b0; // addition
                select_shift = 2'b10; // shift adder output
                select_C = 3'b100; // select C + M >> 1
            end
            S4: begin
                select_in = 1'b0;
                shift_a = 1'b0;
                done = 1'b0;
                increment = 1'b1;
                reset_count = 1'b0;
                select_in_b_adder = 1'b0; // select M
                subtract = 1'b0;
                select_shift = 2'b01; // shift C
                select_C = 3'b010; // select C >> 1
            end
            S5: begin
                select_in = 1'b0;
                shift_a = 1'b0;
                done = 1'b0;
                increment = 1'b0;
                reset_count = 1'b0;
                select_in_b_adder = 1'b0; // select M
                subtract = 1'b1; // subtraction
                select_shift = 2'b00; // no shift
                select_C = 3'b001; // select C
            end
            S6: begin
                select_in = 1'b0;
                shift_a = 1'b0;
                done = 1'b0;
                increment = 1'b0;
                reset_count = 1'b0;
                select_in_b_adder = 1'b0; // select M
                subtract = 1'b1; // subtraction
                select_shift = 2'b00; // no shift
                select_C = 3'b011; // select C - M
            end
            S7: begin
                select_in = 1'b0;
                shift_a = 1'b0;
                done = 1'b1;
                increment = 1'b0;
                reset_count = 1'b0;
                select_in_b_adder = 1'b0; // select M
                subtract = 1'b0; // addition
                select_shift = 2'b00; // no shift
                select_C = 3'b001; // select C
            end
            default: begin
                select_in = 1'b1;
                shift_a = 1'b0;
                done = 1'b0;
                increment = 1'b0;
                reset_count = 1'b1;
                select_in_b_adder = 1'b0;
                subtract = 1'b0;
                select_shift = 2'b0;
                select_C = 3'b000;
            end
        endcase
    end

    // Data path
    // Wires
    wire [384:0] adder_out;
    wire adder_done;
    reg [383:0] C_next;
    reg [380:0] A_next;
    reg [380:0] B_next;
    reg [380:0] M_next;
    reg [383:0] adder_in_b;


    // Adder instantiation
//    adder adder_inst (
//        .clk(clk),
//        .resetn(resetn),
//        .start(1'b1), // always start
//        .subtract(subtract),
//        .in_a(C),
//        .in_b(adder_in_b),
//        .result(adder_out),
//        .done(adder_done)
//    );

    assign adder_out = subtract ? C - adder_in_b : C + adder_in_b;

    // Mux for adder input B
    always @(*) begin
        if (select_in_b_adder) begin
            adder_in_b = {3'b0, B_reg[380:0]}; // select B
        end else begin
            adder_in_b = {3'b0, M_reg[380:0]}; // select M
        end
    end

    // Mux for inputs M and B
    always @(*) begin
        if (select_in) begin
            B_next = in_b;
            M_next = in_m;
        end else begin
            B_next = B_reg;
            M_next = M_reg;  
        end
    end

    // Mux for inputs A
    always @(*) begin
        if (select_in) begin
            A_next = in_a;
        end else if (shift_a) begin
            A_next = A_reg >> 1;
        end else begin
            A_next = A_reg;
        end
    end

    // Mux for C
    always @(*) begin
        case (select_C)
            3'b000: C_next = 384'b0; // 0
            3'b001: C_next = C; // C
            3'b010: C_next = C >> 1; // C >> 1
            3'b011: C_next = adder_out; // C + B or C - M
            3'b100: C_next = adder_out >> 1; // (C + M) >> 1
            default: C_next = 384'b0;
        endcase
    end

    // Registers
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            A_reg <= 381'b0;
            B_reg <= 381'b0;
            M_reg <= 381'b0;
            C <= 384'b0;
        end else begin
            A_reg <= A_next;
            B_reg <= B_next;
            M_reg <= M_next;
            C <= C_next;
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
