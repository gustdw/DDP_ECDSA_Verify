module EC_adder (
    input wire clk,
    input wire resetn,
    input wire start,
    input wire out_read,
    input wire [380:0] Xp,
    input wire [380:0] Yp,
    input wire [380:0] Zp,
    input wire [380:0] Xq,
    input wire [380:0] Yq,
    input wire [380:0] Zq,
    output wire [380:0] Xr,
    output wire [380:0] Yr,
    output wire [380:0] Zr,
    output wire [380:0] mont,
    output wire done_mont,
    output reg done
);

    localparam [380:0] M = 381'h1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab;

    // ------------------ Controller ------------------ //

    // 4 bit state regs

    localparam  IDLE                = 4'd0,     
                START_ADD_MULT      = 4'd1, 
                START_ADD2          = 4'd2, 
                START_ADD_MULT2     = 4'd3, 
                START_X12           = 4'd4, 
                START_X3            = 4'd5, 
                START_SUB           = 4'd6,
                START_X12_2         = 4'd7,
                START_MULT_FINAL    = 4'd8,
                START_ADD_FINAL     = 4'd9,
                DONE_STATE          = 4'd10;

    localparam  MULT_IN1            = 2'd0,
                MULT_IN2            = 2'd1,
                MULT_IN3            = 2'd2,
                MULT_IN4            = 2'd3;  

    reg [3:0] current_state, next_state;

    // Control signal logic
    reg done_next;
    
    reg times_12, times_12_next;
    reg times_12_2, times_12_2_next;
    reg times_3, times_3_next;

    // start signals
    reg start_mult0_next, start_mult1_next, start_mult2_next;
    reg start_mult0, start_mult1, start_mult2;

    reg start_adder0_next, start_adder1_next, start_adder2_next;
    reg start_adder0, start_adder1, start_adder2;

    // read signals
    reg read_mult0_next, read_mult1_next, read_mult2_next;
    reg read_mult0, read_mult1, read_mult2;

    reg read_adder0_next, read_adder1_next, read_adder2_next;
    reg read_adder0, read_adder1, read_adder2;

    // Input selection signals
    reg [1:0] select_in_mult0_next, select_in_mult1_next, select_in_mult2_next;
    reg [1:0] select_in_mult0, select_in_mult1, select_in_mult2;

    reg [3:0] select_in_adder0_next, select_in_adder1_next, select_in_adder2_next;
    reg [3:0] select_in_adder0, select_in_adder1, select_in_adder2;

    // Subtract signals for adders
    reg subtract_adder0_next, subtract_adder1_next, subtract_adder2_next;
    reg subtract_adder0, subtract_adder1, subtract_adder2;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    reg state_entry_buf;

    // This register goes HIGH for exactly one cycle whenever the state changes
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state_entry_buf <= 1'b0;
        end else begin
            // If we are transitioning states, set the buffer to 1
            state_entry_buf <= (current_state != next_state);
        end
    end

    // Next state logic 
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = START_ADD_MULT;
                end else begin
                    next_state = IDLE;
                end
            end
            START_ADD_MULT: begin
                if (adder0_done && !state_entry_buf) begin // Adders always take same cycles -> can just check one
                    next_state = START_ADD2;
                end else begin
                    next_state = START_ADD_MULT;
                end
            end
            START_ADD2: begin
                if (mult0_done & mult1_done & mult2_done) begin // First 3 multiplications done
                    next_state = START_ADD_MULT2;
                end else begin
                    next_state = START_ADD2;
                end
            end
            START_ADD_MULT2: begin
                if (adder0_done & !state_entry_buf) begin // Adders always take same cycles -> can just check one (we use only adder 0-2 here)
                    next_state = START_X12;
                end else begin
                    next_state = START_ADD_MULT2;
                end
            end
            START_X12: begin
                if (adder2_done && adder2_done_buf) begin
                    next_state = START_X3;
                end else begin
                    next_state = START_X12;
                end
            end
            START_X3: begin
                if (mult0_done & mult1_done & mult2_done) begin
                    next_state = START_SUB;
                end else begin
                    next_state = START_X3;
                end
            end
            START_SUB: begin
                if (adder0_done && !state_entry_buf) begin
                    next_state = START_X12_2;
                end else begin
                    next_state = START_SUB;
                end
            end
            START_X12_2: begin
                if (mult0_done & mult1_done & mult2_done) begin
                    next_state = START_MULT_FINAL;
                end else begin
                    next_state = START_X12_2;
                end
            end
            START_MULT_FINAL: begin
                if (mult0_done & mult1_done & mult2_done & !state_entry_buf) begin
                    next_state = START_ADD_FINAL;
                end else begin
                    next_state = START_MULT_FINAL;
                end
            end
            START_ADD_FINAL: begin
                if (adder0_done) begin
                    next_state = DONE_STATE;
                end else begin
                    next_state = START_ADD_FINAL;
                end
            end
            DONE_STATE: begin
                if (out_read) begin
                    next_state = IDLE;
                end else 
                    next_state = DONE_STATE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end


    always @(*) begin
        case (next_state)
            IDLE: begin
                done_next = 1'b0;
                times_12_next = 1'b0;
                times_12_2_next = 1'b0;
                times_3_next = 1'b0;

                start_mult0_next = 1'b0;
                start_mult1_next = 1'b0;
                start_mult2_next = 1'b0;

                start_adder0_next = 1'b0;
                start_adder1_next = 1'b0;
                start_adder2_next = 1'b0;
                
                subtract_adder0_next = 1'b0;
                subtract_adder1_next = 1'b0;
                subtract_adder2_next = 1'b0;

                read_mult0_next = 1'b1;
                read_mult1_next = 1'b1;
                read_mult2_next = 1'b1;

                read_adder0_next = 1'b1;
                read_adder1_next = 1'b1;
                read_adder2_next = 1'b1;

                select_in_mult0_next = MULT_IN1;
                select_in_mult1_next = MULT_IN1;
                select_in_mult2_next = MULT_IN1;

                select_in_adder0_next = IDLE;
                select_in_adder1_next = IDLE;
                select_in_adder2_next = IDLE;

            end
            START_ADD_MULT: begin
                done_next = 1'b0;
                times_12_next = 1'b0;
                times_12_2_next = 1'b0;
                times_3_next = 1'b0;

                start_mult0_next = 1'b1;
                start_mult1_next = 1'b1;
                start_mult2_next = 1'b1;

                start_adder0_next = 1'b1;
                start_adder1_next = 1'b1;
                start_adder2_next = 1'b1;

                subtract_adder0_next = 1'b0;
                subtract_adder1_next = 1'b0;
                subtract_adder2_next = 1'b0;

                read_mult0_next = 1'b0;
                read_mult1_next = 1'b0;
                read_mult2_next = 1'b0;

                read_adder0_next = 1'b1;
                read_adder1_next = 1'b1;
                read_adder2_next = 1'b1;

                select_in_mult0_next = MULT_IN1;
                select_in_mult1_next = MULT_IN1;
                select_in_mult2_next = MULT_IN1;

                select_in_adder0_next = START_ADD_MULT;
                select_in_adder1_next = START_ADD_MULT;
                select_in_adder2_next = START_ADD_MULT;
            end
            START_ADD2: begin
                done_next = 1'b0;
                times_12_next = 1'b0;
                times_12_2_next = 1'b0;
                times_3_next = 1'b0;

                start_mult0_next = 1'b0;
                start_mult1_next = 1'b0;
                start_mult2_next = 1'b0;

                start_adder0_next = 1'b1;
                start_adder1_next = 1'b1;
                start_adder2_next = 1'b1;

                subtract_adder0_next = 1'b0;
                subtract_adder1_next = 1'b0;
                subtract_adder2_next = 1'b0;

                read_mult0_next = 1'b0;
                read_mult1_next = 1'b0;
                read_mult2_next = 1'b0;

                read_adder0_next = 1'b0;
                read_adder1_next = 1'b0;
                read_adder2_next = 1'b0;

                select_in_mult0_next = MULT_IN1;
                select_in_mult1_next = MULT_IN1;
                select_in_mult2_next = MULT_IN1;

                select_in_adder0_next = START_ADD2;
                select_in_adder1_next = START_ADD2;
                select_in_adder2_next = START_ADD2;

            end
            START_ADD_MULT2: begin
                done_next = 1'b0;
                times_12_next = 1'b0;
                times_12_2_next = 1'b0;
                times_3_next = 1'b0;

                start_mult0_next = 1'b1;
                start_mult1_next = 1'b1;
                start_mult2_next = 1'b1;

                start_adder0_next = 1'b1;
                start_adder1_next = 1'b1;
                start_adder2_next = 1'b1;

                subtract_adder0_next = 1'b0;
                subtract_adder1_next = 1'b0;
                subtract_adder2_next = 1'b0;

                read_mult0_next = 1'b1;
                read_mult1_next = 1'b1;
                read_mult2_next = 1'b1;

                read_adder0_next = 1'b1;
                read_adder1_next = 1'b1;
                read_adder2_next = 1'b1;

                select_in_mult0_next = MULT_IN2;
                select_in_mult1_next = MULT_IN2;
                select_in_mult2_next = MULT_IN2;

                select_in_adder0_next = START_ADD_MULT2;
                select_in_adder1_next = START_ADD_MULT2;
                select_in_adder2_next = START_ADD_MULT2;
            end
            START_X12: begin
                done_next = 1'b0;
                times_12_next = 1'b1;
                times_12_2_next = 1'b0;
                times_3_next = 1'b0;

                start_mult0_next = 1'b0;
                start_mult1_next = 1'b0;
                start_mult2_next = 1'b0;

                start_adder0_next = 1'b1;
                start_adder1_next = 1'b1;
                start_adder2_next = 1'b1;

                subtract_adder0_next = 1'b0;
                subtract_adder1_next = 1'b0;
                subtract_adder2_next = 1'b0;

                read_mult0_next = 1'b0;
                read_mult1_next = 1'b0;
                read_mult2_next = 1'b0;

                read_adder0_next = 1'b0;
                read_adder1_next = 1'b0;
                read_adder2_next = 1'b1;

                select_in_mult0_next = MULT_IN2;
                select_in_mult1_next = MULT_IN2;
                select_in_mult2_next = MULT_IN2;

                select_in_adder0_next = START_X12;
                select_in_adder1_next = START_X12;
                select_in_adder2_next = START_X12;
            end
            START_X3: begin
                done_next = 1'b0;
                times_12_next = 1'b0;
                times_12_2_next = 1'b0;
                times_3_next = 1'b1;

                start_mult0_next = 1'b0;
                start_mult1_next = 1'b0;
                start_mult2_next = 1'b0;

                start_adder0_next = 1'b1;
                start_adder1_next = 1'b1;
                start_adder2_next = 1'b1;

                subtract_adder0_next = 1'b0;
                subtract_adder1_next = 1'b0;
                subtract_adder2_next = 1'b1;

                read_mult0_next = 1'b0;
                read_mult1_next = 1'b0;
                read_mult2_next = 1'b0;

                read_adder0_next = 1'b1;
                read_adder1_next = 1'b1;
                read_adder2_next = 1'b0;

                select_in_mult0_next = MULT_IN2;
                select_in_mult1_next = MULT_IN2;
                select_in_mult2_next = MULT_IN2;

                select_in_adder0_next = START_X3;
                select_in_adder1_next = START_X3;
                select_in_adder2_next = START_X3; 
            end         
            START_SUB: begin
                done_next = 1'b0;
                times_12_next = 1'b0;
                times_12_2_next = 1'b0;
                times_3_next = 1'b0;

                start_mult0_next = 1'b0;
                start_mult1_next = 1'b0;
                start_mult2_next = 1'b0;

                start_adder0_next = 1'b1;
                start_adder1_next = 1'b1;
                start_adder2_next = 1'b1;

                subtract_adder0_next = 1'b1;
                subtract_adder1_next = 1'b1;
                subtract_adder2_next = 1'b1;

                read_mult0_next = 1'b1;
                read_mult1_next = 1'b1;
                read_mult2_next = 1'b1;

                read_adder0_next = 1'b1;
                read_adder1_next = 1'b1;
                read_adder2_next = 1'b1;

                select_in_mult0_next = MULT_IN2;
                select_in_mult1_next = MULT_IN2;
                select_in_mult2_next = MULT_IN2;

                select_in_adder0_next = START_SUB;
                select_in_adder1_next = START_SUB;
                select_in_adder2_next = START_SUB;
            end
            START_X12_2: begin
                done_next = 1'b0;
                times_12_next = 1'b1;
                times_12_2_next = 1'b1;
                times_3_next = 1'b0;

                start_mult0_next = 1'b1;
                start_mult1_next = 1'b1;
                start_mult2_next = 1'b1;

                start_adder0_next = 1'b1;
                start_adder1_next = 1'b1;
                start_adder2_next = 1'b1;

                subtract_adder0_next = 1'b0;
                subtract_adder1_next = 1'b0;
                subtract_adder2_next = 1'b0;

                read_mult0_next = 1'b0;
                read_mult1_next = 1'b0;
                read_mult2_next = 1'b0;

                read_adder0_next = 1'b1;
                read_adder1_next = 1'b1;
                read_adder2_next = 1'b1;

                select_in_mult0_next = MULT_IN3;
                select_in_mult1_next = MULT_IN3;
                select_in_mult2_next = MULT_IN3;

                select_in_adder0_next = START_X12_2;
                select_in_adder1_next = START_X12_2;
                select_in_adder2_next = START_X12_2;
            end
            START_MULT_FINAL: begin
                done_next = 1'b0;
                times_12_next = 1'b0;
                times_12_2_next = 1'b0;
                times_3_next = 1'b0;

                start_mult0_next = 1'b1;
                start_mult1_next = 1'b1;
                start_mult2_next = 1'b1;

                start_adder0_next = 1'b0;
                start_adder1_next = 1'b0;
                start_adder2_next = 1'b0;

                subtract_adder0_next = 1'b0;
                subtract_adder1_next = 1'b0;
                subtract_adder2_next = 1'b0;

                read_mult0_next = 1'b1;
                read_mult1_next = 1'b1;
                read_mult2_next = 1'b1;

                read_adder0_next = 1'b1;
                read_adder1_next = 1'b1;
                read_adder2_next = 1'b1;

                select_in_mult0_next = MULT_IN4;
                select_in_mult1_next = MULT_IN4;
                select_in_mult2_next = MULT_IN4;

                select_in_adder0_next = START_MULT_FINAL;
                select_in_adder1_next = START_MULT_FINAL;
                select_in_adder2_next = START_MULT_FINAL;
            end
            START_ADD_FINAL: begin
                done_next = 1'b0;
                times_12_next = 1'b0;
                times_12_2_next = 1'b0;
                times_3_next = 1'b0;

                start_mult0_next = 1'b0;
                start_mult1_next = 1'b0;
                start_mult2_next = 1'b0;

                start_adder0_next = 1'b1;
                start_adder1_next = 1'b1;
                start_adder2_next = 1'b1;

                subtract_adder0_next = 1'b0;
                subtract_adder1_next = 1'b0;
                subtract_adder2_next = 1'b1;

                read_mult0_next = 1'b1;
                read_mult1_next = 1'b1;
                read_mult2_next = 1'b1;

                read_adder0_next = 1'b0;
                read_adder1_next = 1'b0;
                read_adder2_next = 1'b0;

                select_in_mult0_next = MULT_IN1;
                select_in_mult1_next = MULT_IN1;
                select_in_mult2_next = MULT_IN1;

                select_in_adder0_next = START_ADD_FINAL;
                select_in_adder1_next = START_ADD_FINAL;
                select_in_adder2_next = START_ADD_FINAL;
            end
            DONE_STATE: begin
                done_next = 1'b1;
                times_12_next = 1'b0;
                times_12_2_next = 1'b0;
                times_3_next = 1'b0;

                start_mult0_next = 1'b0;
                start_mult1_next = 1'b0;
                start_mult2_next = 1'b0;

                start_adder0_next = 1'b0;
                start_adder1_next = 1'b0;
                start_adder2_next = 1'b0;

                subtract_adder0_next = 1'b0;
                subtract_adder1_next = 1'b0;
                subtract_adder2_next = 1'b0;

                read_mult0_next = 1'b0;
                read_mult1_next = 1'b0;
                read_mult2_next = 1'b0;

                read_adder0_next = 1'b0;
                read_adder1_next = 1'b0;
                read_adder2_next = 1'b0;

                select_in_mult0_next = MULT_IN1;
                select_in_mult1_next = MULT_IN1;
                select_in_mult2_next = MULT_IN1;

                select_in_adder0_next = 0;
                select_in_adder1_next = 0;
                select_in_adder2_next = 0;
            end
            default: begin 
                done_next = 1'b0;
                times_12_next = 1'b0;
                times_12_2_next = 1'b0;
                times_3_next = 1'b0;

                start_mult0_next = 1'b0;
                start_mult1_next = 1'b0;
                start_mult2_next = 1'b0;

                start_adder0_next = 1'b0;
                start_adder1_next = 1'b0;
                start_adder2_next = 1'b0;
                
                subtract_adder0_next = 1'b0;
                subtract_adder1_next = 1'b0;
                subtract_adder2_next = 1'b0;

                read_mult0_next = 1'b1;
                read_mult1_next = 1'b1;
                read_mult2_next = 1'b1;

                read_adder0_next = 1'b1;
                read_adder1_next = 1'b1;
                read_adder2_next = 1'b1;

                select_in_mult0_next = MULT_IN1;
                select_in_mult1_next = MULT_IN1;
                select_in_mult2_next = MULT_IN1;

                select_in_adder0_next = IDLE;
                select_in_adder1_next = IDLE;
                select_in_adder2_next = IDLE;
            end
        endcase
    end

    // Sequential control signal transition
    always @(posedge clk) begin
        done <= done_next;

        times_12 <= times_12_next;
        times_12_2 <= times_12_2_next;
        times_3 <= times_3_next;

        start_mult0 <= start_mult0_next;
        start_mult1 <= start_mult1_next;
        start_mult2 <= start_mult2_next;

        start_adder0 <= start_adder0_next;
        start_adder1 <= start_adder1_next;
        start_adder2 <= start_adder2_next;

        subtract_adder0 <= subtract_adder0_next;
        subtract_adder1 <= subtract_adder1_next;
        subtract_adder2 <= subtract_adder2_next;

        read_mult0 <= read_mult0_next;
        read_mult1 <= read_mult1_next;
        read_mult2 <= read_mult2_next;

        read_adder0 <= read_adder0_next;
        read_adder1 <= read_adder1_next;
        read_adder2 <= read_adder2_next;

        select_in_mult0 <= select_in_mult0_next;
        select_in_mult1 <= select_in_mult1_next;
        select_in_mult2 <= select_in_mult2_next;

        select_in_adder0 <= select_in_adder0_next;
        select_in_adder1 <= select_in_adder1_next;
        select_in_adder2 <= select_in_adder2_next;

    end

    // ------------------ Data Path ------------------ // 

    // 3 montgomery multipliers

    // Mult0 wires 
    reg [380:0] mult0_in_a;
    reg [380:0] mult0_in_b;
    wire [380:0] mult0_in_m;
    wire         mult0_starter;
    reg         mult0_reader;
    wire [380:0] mult0_result;
    wire         mult0_done;


    assign mult0_starter = ((select_in_mult0 == MULT_IN3) | (select_in_mult0 == MULT_IN4)) ? (start_mult0 & !mult0_done) : start_mult0;
    
    always @(*) begin
        if (select_in_mult0 == MULT_IN4) begin 
            if (state_entry_buf) begin
                mult0_reader <= 1'b1;
            end else begin
                mult0_reader <= 1'b0;
            end
        end else begin
            mult0_reader <= read_mult0;
        end
    end
    
    always @(*) begin
        case(select_in_mult0)
            MULT_IN1: begin
                mult0_in_a = Xp;
                mult0_in_b = Xq;
            end
            MULT_IN2: begin
                mult0_in_a = adder0_result_buf2;
                mult0_in_b = adder1_result_buf2;
            end
            MULT_IN3: begin
                mult0_in_a = adder2_result_buf2;
                mult0_in_b = adder0_result_buf;
            end
            MULT_IN4: begin
                mult0_in_a = adder2_result;
                mult0_in_b = adder2_result_buf;
            end
            default: begin
                mult0_in_a = Xp;
                mult0_in_b = Xq;
            end
        endcase
    end
    
    assign mult0_in_m = M;


    montgomery mult0 (
        .clk      (clk        ),
        .resetn   (resetn     ),
        .start    (mult0_starter),
        .out_read (mult0_reader),
        .in_a     (mult0_in_a ),
        .in_b     (mult0_in_b ),
        .in_m     (mult0_in_m ),
        .result   (mult0_result),
        .done     (mult0_done  )
    );

    reg [380:0] mult0_result_buf;
    always @(posedge clk) begin
        if (((current_state == START_ADD2) | (current_state == START_X12_2)) && mult0_done) begin
            mult0_result_buf <= mult0_result;
        end else begin 
            mult0_result_buf <= mult0_result_buf;
        end
    end
    
    reg went_high;
    always @(posedge clk) begin
        if ((current_state == START_ADD2) && !went_high && mult0_done) begin
            went_high <= 1'b1;
        end else if (current_state == IDLE) begin
            went_high <= 1'b0;
        end else begin
            went_high <= went_high;
        end
    end

    // Mult1 wires
    reg [380:0] mult1_in_a;
    reg [380:0] mult1_in_b;
    wire [380:0] mult1_in_m;
    wire         mult1_starter;
    reg          mult1_reader;
    wire [380:0] mult1_result;
    wire         mult1_done;

    assign mult1_in_m     = M;
    
    assign mult1_starter = ((select_in_mult1 == MULT_IN3) | (select_in_mult1 == MULT_IN4)) ? (start_mult1 & !mult1_done) : start_mult1;

    always @(*) begin
        if (select_in_mult1 == MULT_IN4) begin 
            if (state_entry_buf) begin
                mult1_reader <= 1'b1;
            end else begin
                mult1_reader <= 1'b0;
            end
        end else begin
            mult1_reader <= read_mult1;
        end
    end

    always @(*) begin
        case(select_in_mult1)
            MULT_IN1: begin
                mult1_in_a = Yp;
                mult1_in_b = Yq;
            end
            MULT_IN2: begin
                mult1_in_a = adder2_result_buf2;
                mult1_in_b = adder0_result;
            end
            MULT_IN3: begin
                mult1_in_a = adder2_result_buf;
                mult1_in_b = adder1_result_buf2;
            end
            MULT_IN4: begin
                mult1_in_a = adder2_result_buf2;
                mult1_in_b = adder1_result_buf2;
            end
            default: begin
                mult1_in_a = Yp;
                mult1_in_b = Yq;
            end
        endcase
    end

    montgomery mult1 (
        .clk      (clk        ),
        .resetn   (resetn    ),
        .start    (mult1_starter),
        .out_read (mult1_reader),
        .in_a     (mult1_in_a ),
        .in_b     (mult1_in_b ),
        .in_m     (mult1_in_m ),
        .result   (mult1_result),
        .done     (mult1_done  )
    );

    reg [380:0] mult1_result_buf;
    always @(posedge clk) begin
        if (((current_state == START_ADD2) | (current_state == START_X12_2)) && mult1_done) begin
            mult1_result_buf <= mult1_result;
        end else begin 
            mult1_result_buf <= mult1_result_buf;
        end
    end

    // Mult2 wires
    reg [380:0] mult2_in_a;
    reg [380:0] mult2_in_b;
    wire [380:0] mult2_in_m;
    wire         mult2_starter;
    reg          mult2_reader;
    wire [380:0] mult2_result;
    wire         mult2_done;

    assign mult2_in_m     = M;
    assign mult2_starter = ((select_in_mult2 == MULT_IN3) | (select_in_mult2 == MULT_IN4)) ? (start_mult2 & !mult2_done) : start_mult2;

    always @(*) begin
        if (select_in_mult2 == MULT_IN4) begin 
            if (state_entry_buf) begin
                mult2_reader <= 1'b1;
            end else begin
                mult2_reader <= 1'b0;
            end
        end else begin
            mult2_reader <= read_mult2;
        end
    end

    always @(*) begin
        case(select_in_mult2)
            MULT_IN1: begin
                mult2_in_a = Zp;
                mult2_in_b = Zq;
            end
            MULT_IN2: begin
                mult2_in_a = adder1_result;
                mult2_in_b = adder2_result;
            end
            MULT_IN3: begin
                mult2_in_a = adder0_result_buf2;
                mult2_in_b = adder0_result_buf;
            end
            MULT_IN4: begin
                mult2_in_a = adder0_result_buf2;
                mult2_in_b = adder2_result;
            end
            default: begin
                mult2_in_a = Yp;
                mult2_in_b = Yq;
            end
        endcase
    end

    montgomery mult2 (
        .clk      (clk        ),
        .resetn   (resetn     ),
        .start    (mult2_starter),
        .out_read (mult2_reader),
        .in_a     (mult2_in_a ),
        .in_b     (mult2_in_b ),
        .in_m     (mult2_in_m ),
        .result   (mult2_result),
        .done     (mult2_done  )
    );

    reg [380:0] mult2_result_buf;
    always @(posedge clk) begin
        if (((current_state == START_ADD2) | (current_state == START_X12_2)) && mult2_done) begin
            mult2_result_buf <= mult2_result;
        end else begin 
            mult2_result_buf <= mult2_result_buf;
        end
    end

   
    // 3 modular adders

    // Adder0 wires
    reg [380:0] adder0_in_a;
    reg [380:0] adder0_in_b;
    wire [380:0] adder0_in_m;
    wire [380:0] adder0_result;
    wire        adder0_reader;
    wire        adder0_done;
    reg         adder0_done_buf;

    assign adder0_in_m     = M;
    
    assign adder0_reader = times_3 ? !(adder0_done && adder0_done_buf) : read_adder0;

    always @(*) begin
        case (select_in_adder0)
            IDLE: begin 
                adder0_in_a = Xp;
                adder0_in_b = Yp;
            end
            START_ADD_MULT: begin
                adder0_in_a = Xp;
                adder0_in_b = Yp;
            end
            START_ADD2: begin
                adder0_in_a = Zq;
                adder0_in_b = Xq;
            end
            START_ADD_MULT2: begin
                adder0_in_a = mult0_result;
                adder0_in_b = mult1_result;
            end
            START_X12: begin
                adder0_in_a = mult2_result_buf;
                adder0_in_b = mult2_result_buf;
            end
            START_X3: begin
                adder0_in_a = mult0_result_buf;
                adder0_in_b = adder0_done_buf ? adder0_result : mult0_result_buf;
            end
            START_SUB: begin
                adder0_in_a = mult0_result;
                adder0_in_b = adder0_result_buf2;
            end
            START_X12_2: begin
                adder0_in_a = adder1_result;
                adder0_in_b = adder1_result;
            end
            START_ADD_FINAL: begin
                adder0_in_a = mult1_result_buf;
                adder0_in_b = mult2_result_buf;
            end
            default: begin
                adder0_in_a = Xp;
                adder0_in_b = Xq;
            end
        endcase
    end

    modadder adder0 (
        .in_a     (adder0_in_a ),
        .in_b     (adder0_in_b ),
        .in_m     (adder0_in_m ),
        .subtract (subtract_adder0),
        .start    (start_adder0),
        .clk      (clk         ),
        .resetn   (resetn      ),
        .result   (adder0_result),
        .out_read (adder0_reader),
        .done     (adder0_done )
    );

    reg [380:0] adder0_result_buf, adder0_result_buf2;
    always @(posedge clk) begin
        if (((current_state == START_ADD_MULT) | (current_state == START_ADD_MULT2) | (current_state == START_SUB)) && adder0_done) begin
            adder0_result_buf <= adder0_result;
            adder0_result_buf2 <= adder0_result_buf;
        end else begin
            adder0_result_buf <= adder0_result_buf;
            adder0_result_buf2 <= adder0_result_buf2;
        end
    end

    always @(posedge clk) begin
        adder0_done_buf <= times_3 ? ((adder0_done && !state_entry_buf) || adder0_done_buf) : 1'b0;
    end

    // Adder1 wires
    reg [380:0] adder1_in_a;
    reg [380:0] adder1_in_b;
    wire [380:0] adder1_in_m;
    wire         adder1_starter;
    wire         adder1_reader;
    wire [380:0] adder1_result;
    wire         adder1_done;

    assign adder1_in_m     = M;

    assign adder1_starter = times_12 ? adder0_done : start_adder1;
    assign adder1_reader  = times_3 ? state_entry_buf : read_adder1;

    always @(*) begin
        case (select_in_adder1)
            IDLE: begin 
                adder1_in_a = Xq;
                adder1_in_b = Yq;
            end
            START_ADD_MULT: begin
                adder1_in_a = Xq;
                adder1_in_b = Yq;
            end
            START_ADD2: begin
                adder1_in_a = Yp;
                adder1_in_b = Zp;
            end
            START_ADD_MULT2: begin
                adder1_in_a = mult0_result;
                adder1_in_b = mult2_result;
            end
            START_X12: begin
                adder1_in_a = adder0_result;
                adder1_in_b = adder0_result;
            end
            START_X3: begin
                adder1_in_a = mult1_result_buf;
                adder1_in_b = adder2_result;
            end
            START_SUB: begin
                adder1_in_a = mult1_result;
                adder1_in_b = adder1_result_buf2;
            end
            START_X12_2: begin
                adder1_in_a = adder0_result;
                adder1_in_b = adder0_result;
            end
            START_ADD_FINAL: begin
                adder1_in_a = mult1_result;
                adder1_in_b = mult2_result;
            end
            default: begin
                adder1_in_a = Xp;
                adder1_in_b = Xq;
            end
        endcase
    end

    modadder adder1 (
        .in_a     (adder1_in_a ),
        .in_b     (adder1_in_b ),
        .in_m     (adder1_in_m ),
        .subtract (subtract_adder1),
        .start    (adder1_starter),
        .clk      (clk         ),
        .resetn   (resetn      ),
        .out_read (adder1_reader),
        .result   (adder1_result),
        .done     (adder1_done )
    );

    reg [380:0] adder1_result_buf, adder1_result_buf2;
    always @(posedge clk) begin
        if (((current_state == START_ADD_MULT) | (current_state == START_ADD_MULT2) | (current_state == START_SUB)) && adder1_done) begin
            adder1_result_buf <= adder1_result;
            adder1_result_buf2 <= adder1_result_buf;
        end else begin
            adder1_result_buf <= adder1_result_buf;
            adder1_result_buf2 <= adder1_result_buf2;
        end
    end

    // Adder2 wires
    reg [380:0] adder2_in_a;
    reg [380:0] adder2_in_b;
    wire [380:0] adder2_in_m;
    wire [380:0] adder2_result;
    wire         adder2_starter;
    wire         adder2_reader;
    wire         adder2_done;
    reg          adder2_done_buf;

    assign adder2_in_m     = M;

    assign adder2_starter = times_12 ? (adder1_done || adder2_done_buf) : start_adder2;
    
    assign adder2_reader = times_12_2 ? !(adder2_done && adder2_done_buf) : read_adder2;

    always @(*) begin
        case (select_in_adder2)
            IDLE: begin 
                adder2_in_a = Xp;
                adder2_in_b = Zp;
            end
            START_ADD_MULT: begin
                adder2_in_a = Xp;
                adder2_in_b = Zp;
            end
            START_ADD2: begin
                adder2_in_a = Yq;
                adder2_in_b = Zq;
            end
            START_ADD_MULT2: begin
                adder2_in_a = mult1_result;
                adder2_in_b = mult2_result;
            end
            START_X12: begin
                adder2_in_a = adder1_result;
                adder2_in_b = adder2_done_buf ? adder2_result : adder1_result;
            end
            START_X3: begin
                adder2_in_a = mult1_result_buf;
                adder2_in_b = adder2_result;
            end
            START_SUB: begin
                adder2_in_a = mult2_result;
                adder2_in_b = adder2_result_buf2;
            end
            START_X12_2: begin
                adder2_in_a = adder1_result;
                adder2_in_b = adder2_done_buf ? adder2_result : adder1_result;
            end
            START_ADD_FINAL: begin
                adder2_in_a = mult0_result_buf;
                adder2_in_b = mult0_result;
            end
            default: begin
                adder2_in_a = Xp;
                adder2_in_b = Xq;
            end
        endcase
    end


    modadder adder2 (
        .in_a     (adder2_in_a ),
        .in_b     (adder2_in_b ),
        .in_m     (adder2_in_m ),
        .subtract (subtract_adder2),
        .start    (adder2_starter),
        .clk      (clk         ),
        .resetn   (resetn     ),
        .out_read (adder2_reader),
        .result   (adder2_result),
        .done     (adder2_done )
    );

    reg [380:0] adder2_result_buf, adder2_result_buf2;
    always @(posedge clk) begin
        if (((current_state == START_ADD_MULT) | (current_state == START_ADD_MULT2) | (current_state == START_SUB)) && adder2_done) begin
            adder2_result_buf <= adder2_result;
            adder2_result_buf2 <= adder2_result_buf;
        end else begin
            adder2_result_buf <= adder2_result_buf;
            adder2_result_buf2 <= adder2_result_buf2;
        end
    end

    always @(posedge clk) begin
        adder2_done_buf <= times_12 ? (adder2_done || adder2_done_buf) : 1'b0;
    end
    
    assign Xr = adder2_result;
    assign Yr = adder1_result;
    assign Zr = adder0_result;
    assign mont = mult0_result;
    assign done_mont = (mult0_done && !went_high);
    
    wire test = adder0_done & !state_entry_buf;

endmodule