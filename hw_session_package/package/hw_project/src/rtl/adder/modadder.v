`timescale 1ns / 1ps

module modadder(
    input  wire [380:0] in_a,
    input  wire [380:0] in_b,
    input  wire [380:0] in_m,
    input  wire         subtract,
    input  wire         start,
    input  wire         clk,
    input  wire         resetn,
    input  wire         out_read,
    output reg [380:0]  result,
    output reg          done
); 

    // --- State Machine Definitions ---
    localparam S_IDLE   = 2'b00; // Waiting for start
    localparam S_CALC_1 = 2'b01; // First pass (A +/- B)
    localparam S_CALC_2 = 2'b10; // Second pass (Result +/- M)
    localparam S_DONE   = 2'b11; // Holding result

    reg [1:0] state;
    reg [1:0] next_state;

    // --- Signals ---
    
    // Shared Adder Signals
    wire [384:0] adder_result;
    wire         adder_done;
    wire         adder_cout;
    reg          adder_start; // Controlled by logic
    
    // Muxed Inputs for the Adder
    reg [384:0] mux_in_a;
    reg [384:0] mux_in_b;
    reg         mux_subtract;

    // Intermediate Storage (Output of Pass 1)
    reg [381:0] reg_pass1;
    reg         cout_pass1;
    reg         done_buf;
    
    always @(posedge clk) begin
        done_buf <= adder_done;
    end

    // Internal wires for final logic
    wire [380:0] final_calc_out;

    // --- FSM Logic ---
    
    // 1. State Register
    always @(posedge clk or negedge resetn) begin
        if (!resetn) 
            state <= S_IDLE;
        else 
            state <= next_state;
    end

    // 2. Next State Logic
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (start) 
                    next_state = S_CALC_1;
            end
            S_CALC_1: begin
                // When Adder finishes Pass 1, move to Pass 2
                if (adder_done) 
                    next_state = S_CALC_2;
            end
            S_CALC_2: begin
                // When Adder finishes Pass 2, move to Done
                if (adder_done) 
                    next_state = S_DONE;
            end
            S_DONE: begin
                // Wait for handshake
                if (out_read) 
                    next_state = S_IDLE;
            end
            default: next_state = S_IDLE;
        endcase
    end

    // 3. Output Logic (Done Signal)
    always @(*) begin
        done = (state == S_DONE);
    end

    // --- Datapath & Muxing ---

    // Logic to select inputs for the single Adder based on State
    always @(*) begin
        // Defaults (avoid latches)
        mux_in_a     = {3'b0, in_a};
        mux_in_b     = {3'b0, in_b};
        mux_subtract = subtract;
        adder_start  = 1'b0;

        case (state)
            S_IDLE: begin
                // Pass 1 Setup (Pre-load)
                mux_in_a     = {3'b0, in_a};
                mux_in_b     = {3'b0, in_b};
                mux_subtract = subtract;
                // Kick off adder if start is high
                adder_start  = start; 
            end

            S_CALC_1: begin
                // Maintain Pass 1 inputs
                mux_in_a     = {3'b0, in_a};
                mux_in_b     = {3'b0, in_b};
                mux_subtract = subtract;
            end

            S_CALC_2: begin
                // Pass 2 Setup: 
                // Input A is result of Pass 1 (reg_pass1)
                // Input B is Modulo (in_m)
                // Subtract is Inverted
                mux_in_a     = {2'b0, reg_pass1}; // Note: Original code used 2 bit padding here
                mux_in_b     = {3'b0, in_m};
                mux_subtract = ~subtract;
                adder_start = done_buf;
                // No start trigger here, it was triggered at the end of CALC_1
            end
        endcase
    end

    // --- Single Adder Instantiation ---
    adder shared_adder (
        .clk      (clk),
        .resetn   (resetn),
        .start    (adder_start), 
        .subtract (mux_subtract), 
        .in_a     (mux_in_a),
        .in_b     (mux_in_b),
        .result   (adder_result),
        .done     (adder_done)
    );
    
    assign adder_cout = adder_result[384];

    // --- Register Management ---

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            reg_pass1  <= 0;
            cout_pass1 <= 0;
            result     <= 0;
        end else begin
            
            // Capture Pass 1 Results
            if (state == S_CALC_1 && adder_done) begin
                reg_pass1  <= adder_result[381:0];
                cout_pass1 <= adder_result[384];
            end

            // Capture Final Results (End of Pass 2)
            if (state == S_CALC_2 && adder_done) begin
                // Replicating the exact logic from your original code:
                // If subtract=1 (A-B):
                //    Borrow (cout_pass1=1) -> Use Adder Pass 2 ( (A-B)+M )
                //    No Borrow             -> Use Buffer Pass 1 ( A-B )
                // If subtract=0 (A+B):
                //    Carry (adder_cout=1)  -> Use Buffer Pass 1 ( (A+B)-M produced carry? This logic maps to your original mux)
                //    *Note*: In your original code: (cout_adder2 ? res_buf1 : out)
                
                if (subtract) begin
                    result <= (cout_pass1) ? adder_result[380:0] : reg_pass1[380:0];
                end else begin
                    result <= (adder_cout) ? reg_pass1[380:0] : adder_result[380:0];
                end
            end
        end
    end

endmodule