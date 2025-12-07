`timescale 1ns / 1ps

module montgomery(
  input           clk,
  input           resetn,
  input           start,
  input  [380:0] in_a,
  input  [380:0] in_b,
  input  [380:0] in_m,
  input          out_read,
  output [380:0] result,
  output reg         done
    );

// Controller 
// State encoding (5 states)

    localparam S0 = 3'b000;
    localparam S1 = 3'b001;
    localparam S2 = 3'b010;
    localparam S3 = 3'b011;
    localparam S4 = 3'b100;
    localparam S5 = 3'b101;
    localparam S6 = 3'b110;

    reg [2:0] state, next_state;
    reg [8:0] count; // counter for 381 bits


    wire [383:0] C1_sum, C1_carry;
    wire [383:0] C2_sum, C2_carry;
    wire [383:0] C_sum_next, C_carry_next;
    reg [383:0] C_sum, C_carry;
    reg [383:0] C;
    reg [380:0] B_reg, A_reg, M_reg;
    reg [383:0] B2_reg, M2_reg, B3_reg, M3_reg;
    reg [384:0] M_neg_reg;
    reg [383:0] B_c, M_c;

    // Control signals
    reg increment, reset_count;

    // Sequential logic for state transition
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state <= S0;
        end else begin
            state <= next_state;
        end
    end

    reg start_buf;
    reg start_buf2;
    always @(posedge clk) begin
        start_buf <= start;
        start_buf2 <= start_buf;
    end
    
    


    // Combinational logic for next state
    always @(*) begin
        case (state)
            S0: begin
                if (start_buf2) begin
                    next_state = S1;
                end else begin
                    next_state = S0;
                end
            end
            S1: begin
                if (count == 9'd189) begin
                    next_state = S2;
                end else begin
                    next_state = S1;
                end
            end
            S2: begin
                next_state = S3;
            end
            S3: begin
                next_state = S4;
            end
            S4: begin
                if (sub_out[384] == 1'b0) begin
                    next_state = S4;
                end else begin
                    next_state = S5;
                end
            end
            S5: begin
                if (out_read) begin
                    next_state = S0;
                end else begin
                    next_state = S5;
                end
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
                reset_count = 1'b1;
                increment = 1'b0;
                done = 1'b0;
            end
            S1: begin
                reset_count = 1'b0;
                increment = 1'b1;
                done = 1'b0;
            end
            S2: begin
                reset_count = 1'b0;
                increment = 1'b0;
                done = 1'b0;
            end
            S3: begin
                reset_count = 1'b0;
                increment = 1'b0;
                done = 1'b0;
            end
            S4: begin
                reset_count = 1'b0;
                increment = 1'b0;
                done = 1'b0;
            end
            S5: begin
                reset_count = 1'b0;
                increment = 1'b0;
                done = 1'b1;
            end
            default: begin
                reset_count = 1'b0;
                increment = 1'b0;
                done = 1'b0;
            end
        endcase
    end


// Data path

    // Mux do decide B_c
    always @(*) begin
        case (A_reg[1:0])
            2'b00: B_c = 384'b0;
            2'b01: B_c = {3'b0, B_reg};
            2'b10: B_c = B2_reg;
            2'b11: B_c = B3_reg;
            default: B_c = 384'b0;
        endcase
    end

    // CSA instances
    carry_save_adder_384 csa1 (
        .A_sum   (C_sum   ),
        .A_carry (C_carry << 1 ),
        .B       (B_c  ),
        .C_sum   (C1_sum   ),
        .C_carry (C1_carry )
    );

    // u to decide M_c
    wire [1:0] r, u;
    assign u = (C1_sum[1:0] + {C1_carry[0], 1'b0}) & 2'b11; // 2 lsb of C in canonical form
    
    // Mux do decide M_c
    always @(*) begin
        if (u == 2'b00 || (state == S2 && u[0] == 1'b0) ) begin
            M_c = 384'b0;
        end else if (state == S2 && u[0] == 1'b1) begin
            M_c = {3'b0, M_reg};
        end else if ({u, M_reg[1:0]} == 4'b0101 || {u, M_reg[1:0]} == 4'b1111) begin
            M_c = M3_reg;
        end else if (u == 2'b10) begin
            M_c = M2_reg;
        end else if ({u, M_reg[1:0]} == 4'b1101 || {u, M_reg[1:0]} == 4'b0111) begin
            M_c = {3'b0, M_reg};
        end else begin
            M_c = 384'b0;
        end
    end

    // Second CSA instance for C2
    carry_save_adder_384 csa2 (
        .A_sum   (C1_sum   ),
        .A_carry (C1_carry << 1),
        .B       (M_c  ),
        .C_sum   (C2_sum   ),
        .C_carry (C2_carry )
    );

    // We need to create a correction factor to be able to shift right by 2 without losing information
    wire [3:0] k = C2_sum[1:0] + {C2_carry[1:0], 1'b0};

    // CSA for correction
    // Depending on state S2 or not, we shift by 1 or 2 (division by 2 or 4) => different correction
    wire [383:0] Correction_sum_in, Correction_carry_in, Correction_term;
    assign Correction_sum_in   = (state == S2) ? (C2_sum >> 1) : (C2_sum >> 2);
    assign Correction_carry_in = (state == S2) ? ({C2_carry[383:1], 1'b0}) : ({1'b0, C2_carry[383:2], 1'b0});
    assign Correction_term     = (state == S2) ? ({383'b0, C2_carry[0]}) : ({383'b0, (k[3] | k[2])} );

    carry_save_adder_384 csa_correction (
        .A_sum   (Correction_sum_in   ),
        .A_carry (Correction_carry_in),
        .B       (Correction_term  ),
        .C_sum   (C_sum_next   ),
        .C_carry (C_carry_next )
    );

    // Subtractor for final C or C-M
    wire [384:0] sub_out;
    assign sub_out = C + M_neg_reg;

    
    // Registers for next values
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            B_reg <= 381'b0;
            M_reg <= 381'b0;
            M2_reg <= 384'b0;
            M3_reg <= 384'b0;
            M_neg_reg <= 384'b0;
        end else begin
            if ((state == S0) & (!start_buf2)) begin
                B_reg <= in_b;
                M_reg <= in_m;
                M2_reg <= {2'b0, in_m, 1'b0};
                M3_reg <= {3'b0, in_m} + {2'b0, in_m, 1'b0};
                M_neg_reg <= -{3'b0, in_m};
            end else begin
                B_reg <= B_reg;
                M_reg <= M_reg;
                M2_reg <= M2_reg;
                M3_reg <= M3_reg;
                M_neg_reg <= M_neg_reg;
            end
        end
    end

    // A register shift
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            A_reg <= 381'b0;
        end else begin
            if ((state == S0)) begin
                if (!start_buf2) begin
                    A_reg <= in_a;
                end else begin
                    A_reg <= A_reg;
                end
            end else begin
                A_reg <= A_reg >> 2;
            end
        end
    end

    // B regs
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin 
            C_sum <= 384'b0;
            C_carry <= 384'b0;
            B2_reg <= 384'b0;
            B3_reg <= 384'b0;
        end else if (state == S0) begin
            B2_reg <= {2'b0, B_reg, 1'b0};
            B3_reg <= {3'b0, B_reg} + {2'b0, B_reg, 1'b0};
            C_sum <= 384'b0;
            C_carry <= 384'b0;
        end else begin 
            B2_reg <= B2_reg;
            B3_reg <= B3_reg;
            C_sum <= C_sum_next;
            C_carry <= C_carry_next;
        end
    end
    
    // C register
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            C <= 384'b0;
        end else begin
            case (state)
                S0: begin
                    C <= 384'b0;
                end
                S1: begin
                    C <= C_sum + {C_carry, 1'b0};
                end
                S2: begin
                    C <= C_sum + {C_carry, 1'b0};
                end
                S3: begin
                    C <= C_sum + {C_carry, 1'b0};
                end
                S4: begin
                    C <= sub_out[384] ? C : sub_out[383:0];
                end
                S5: begin
                    C <= C;
                end
                default: begin
                    C <= 384'b0;
                end
            endcase
        end
    end

    
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

    // Result and done signal
    assign result = C[380:0];
    
    // testbench wires
    
//    wire eq_CSA1 = C1_sum + {C1_carry, 1'b0} == C_sum + {C_carry, 1'b0} + B_c;
//    wire eq_CSA2 = C2_sum + {C2_carry, 1'b0} == C1_sum + {C1_carry, 1'b0} + M_c;
//    wire [384:0] C4_next = (C2_sum + {C2_carry, 1'b0});
//    wire [383:0] Ccalc_next = C4_next >> 2;
//    wire eq_CSA_corr = C_sum_next + {C_carry_next, 1'b0} == Ccalc_next;
//    wire eq_end = C_sum_next + {C_carry_next, 1'b0} == (C_sum + {C_carry, 1'b0} + B_c + M_c) >> 2;
//    wire [383:0] C_next = C_sum + {C_carry, 1'b0};

endmodule

