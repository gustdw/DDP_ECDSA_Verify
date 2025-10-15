`timescale 1ns / 1ps

module warmup2_adder(
    input  wire         clk,
    input  wire         resetn,
    input  wire         start,
    input  wire         Cin,
    input  wire [383:0] A,
    input  wire [383:0] B,
    output wire [384:0] C,
    output wire         done);

    // Task 1
    // Try to understand the description of the A_mid_buf1 and B_mid_buf1 registers
    // The registers store 128 bits each
    // First, we describe a register using the most structured method:
    // Here, we describe a wire A_mid_buf1_D to which we will assign the input of the register
    // And a register A_mid_buf1_Q which will implement the physical register and which we use to refer the content of the register
    // Typically, we would also describe a control signal A_mid_buf1_en, which controls when the input will be stored into the register
    // However, in the pipelined adder that we want to describe, we want to update all registers every clock cycle and therefore don't need this signal

    wire [127:0] A_mid_buf1_D;
    reg  [127:0] A_mid_buf1_Q;
    // reg          A_mid_buf1_en;

    assign A_mid_buf1_D = A[255:128];

    always @(posedge clk)
    begin
        if(~resetn)         A_mid_buf1_Q <= 128'd0;
        // else if (A_mid_buf1_en)   A_mid_buf1_Q <= A_mid_buf1_D;
        else                A_mid_buf1_Q <= A_mid_buf1_D;
    end

    // To describe B_mid_buf1, we will use a slightly more compact method, that 'computes' the input of the register (in this case the selection of the correct bits of B) 
    // within the always @(posedge clk) block:

    reg  [127:0] B_mid_buf1;

    always @(posedge clk)
    begin
        if(~resetn)         B_mid_buf1 <= 128'd0;
        else                B_mid_buf1 <= B[255:128];
    end

    // Task 2
    // Describe two 128 bit registers for A_top_buf1 and B_top_buf1 with your prefered syntax
    wire [127:0] A_top_buf1_D;
    reg  [127:0] A_top_buf1_Q;
    // reg          A_top_buf1_en;

    assign A_top_buf1_D = A[383:256];

    always @(posedge clk)
    begin
        if(~resetn)         A_top_buf1_Q <= 128'd0;
        else                A_top_buf1_Q <= A_top_buf1_D;
    end

    wire [127:0] B_top_buf1_D;
    reg  [127:0] B_top_buf1_Q;

    assign B_top_buf1_D = B[383:256];

    always @(posedge clk)
    begin
        if(~resetn)         B_top_buf1_Q <= 128'd0;
        else                B_top_buf1_Q <= B_top_buf1_D;
    end

    // Task 3
    // Describe the adder for the first pipeline stage
    // Describe registers for Cout1_low_buf1 and Res_low_buf1 and connect their inputs
    // How large should these registers be?
    // (Implemented below already for you in both syntaxes, be sure you understand it)

    wire            Cout1_low_buf1_D;
    reg             Cout1_low_buf1_Q;
    wire    [127:0] Res_low_buf1_D;
    reg     [127:0] Res_low_buf1_Q;

    assign {Cout1_low_buf1_D, Res_low_buf1_D} = A[127:0] + B[127:0] + Cin;
    
    always @(posedge clk)
    begin
        if(~resetn)         Res_low_buf1_Q <= 128'd0;
        else                Res_low_buf1_Q <= Res_low_buf1_D;
    end

    always @(posedge clk)
    begin
        if(~resetn)         Cout1_low_buf1_Q <= 1'd0;
        else                Cout1_low_buf1_Q <= Cout1_low_buf1_D;
    end

    // Or the shorter version:

    // wire    [128:0] Res1;
    // reg     [127:0] Res_low_buf1;
    // reg             Cout1_low_buf1;

    // assign {Cout1, Res1} = A[127:0] + B[127:0] + Cin;

    // always @(posedge clk)
    // begin
    //     if(~resetn) begin        
    //         Res_low_buf1 <= 128'd0;
    //         Cout1_low_buf1 <= 1'd0;
    //     end
    //     else begin              
    //         Res_low_buf1 <= Res1[127:0];
    //         Cout1_low_buf1 <= Res1[128];
    //     end
    // end


    // Task 4
    // Describe the adder of the second stage with the always @(*) syntax
    // This syntax is mainly useful in finite state machines that you will have to describe later in the project
    // This syntax allows you to use if/else and case statements in the always block, which can be easier to reason about
    // (Implemented below already for you, be sure you understand it)       

    wire     [127:0] Res_mid_buf2_D; 
    reg      [127:0] Res_mid_buf2_Q;
    wire Cout2_mid_buf2_D;
    reg Cout2_mid_buf2_Q;

    assign {Cout2_mid_buf2_D, Res_mid_buf2_D} = A_mid_buf1_Q + B_mid_buf1 + Cout1_low_buf1_Q;

    always @(posedge clk)
    begin
        if(~resetn) begin        
            Res_mid_buf2_Q <= 128'd0;
            Cout2_mid_buf2_Q <= 1'd0;
        end
        else begin              
            Res_mid_buf2_Q <= Res_mid_buf2_D;
            Cout2_mid_buf2_Q <= Cout2_mid_buf2_D;
        end
    end

    // This syntax is identical to

    // wire    [128:0] Res2;
    // assign Res2 = A_mid_buf1_Q + B_mid_buf1 + Cout1_low_buf1_Q;

    
    // Task 5
    // Describe the remainder of the second pipeline stage (describe the 5 registers and connect their inputs)
    wire [127:0] A_top_buf2_D;
    reg [127:0] A_top_buf2_Q;
    assign A_top_buf2_D = A_top_buf1_Q;
    
    wire [127:0] B_top_buf2_D;
    reg [127:0] B_top_buf2_Q;
    assign B_top_buf2_D = B_top_buf1_Q;

    wire [127:0] Res_low_buf2_D;
    reg [127:0] Res_low_buf2_Q;
    assign Res_low_buf2_D = Res_low_buf1_Q;

    always @(posedge clk) begin
        if(~resetn) begin        
            A_top_buf2_Q <= 128'd0;
            B_top_buf2_Q <= 128'd0;
            Res_low_buf2_Q <= 128'd0;
        end
        else begin              
            A_top_buf2_Q <= A_top_buf2_D;
            B_top_buf2_Q <= B_top_buf2_D;
            Res_low_buf2_Q <= Res_low_buf2_D;
        end
    end

    // Task 6
    // Describe the third and last pipeline stage
    wire [127:0] Res_low_buf3_D;
    reg [127:0] Res_low_buf3_Q;
    assign Res_low_buf3_D = Res_low_buf2_Q;

    wire [127:0] Res_mid_buf3_D;
    reg [127:0] Res_mid_buf3_Q;
    assign Res_mid_buf3_D = Res_mid_buf2_Q;

    always @(posedge clk) begin
        if (~resetn) begin
            Res_low_buf3_Q = 128'd0;
            Res_mid_buf3_Q = 128'd0;
        end
        else begin
            Res_low_buf3_Q = Res_low_buf3_D;
            Res_mid_buf3_Q = Res_mid_buf3_D;
        end
    end

    wire [127:0] Res_top_buf3_D;
    reg [127:0] Res_top_buf3_Q;
    wire Cout3_top_buf3_D;
    reg Cout3_top_buf3_Q;

    assign {Cout3_top_buf3_D, Res_top_buf3_D} = A_top_buf2_Q + B_top_buf2_Q + Cout2_mid_buf2_Q;
    always @(posedge clk) begin
        if(~resetn) begin        
            Res_top_buf3_Q <= 128'd0;
            Cout3_top_buf3_Q <= 1'd0;
        end
        else begin              
            Res_top_buf3_Q <= Res_top_buf3_D;
            Cout3_top_buf3_Q <= Cout3_top_buf3_D;
        end
    end


    // Task 7
    // Compose and assign the result to the output wire C
    assign C = {Cout3_top_buf3_Q, Res_top_buf3_Q, Res_mid_buf3_Q, Res_low_buf3_Q};


    // Task 8
    // Descirbe the done signal which is the start signal delayed for every register buffer in the path  
    wire start_buf1_D, start_buf2_D, start_buf3_D;
    reg start_buf1_Q, start_buf2_Q, start_buf3_Q;

    assign start_buf1_D = start;
    assign start_buf2_D = start_buf1_Q;
    assign start_buf3_D = start_buf2_Q;

    always @(posedge clk) begin
        start_buf1_Q <= start_buf1_D;
        start_buf2_Q <= start_buf2_D;
        start_buf3_Q <= start_buf3_D;
    end
    assign done = start_buf3_Q;

    // Task 9
    // Simulate (and debug) using tb_warmup2_adder.v (right click and select "Set as Top")
    // Reason about how many clock cycles you have to wait until the result appears at the output



endmodule
