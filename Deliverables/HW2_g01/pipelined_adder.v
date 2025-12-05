module pipelined_adder(
    input  wire         clk,
    input  wire         resetn,
    input  wire         start,
    input  wire         Cin,
    input  wire [383:0] A,
    input  wire [383:0] B,
    output wire [384:0] C,
    output wire         done);

    // Stage 1 registers
        // Mid registers
    wire [127:0] A_mid_buf1_D;
    reg  [127:0] A_mid_buf1_Q;
    assign A_mid_buf1_D = A[255:128];

    wire [127:0] B_mid_buf1_D;
    reg  [127:0] B_mid_buf1_Q;
    assign B_mid_buf1_D = B[255:128];

    always @(posedge clk)
    begin
        if(~resetn) begin
                A_mid_buf1_Q <= 128'd0;
                B_mid_buf1_Q <= 128'd0;
            end
        else begin
                A_mid_buf1_Q <= A_mid_buf1_D;
                B_mid_buf1_Q <= B_mid_buf1_D;
            end
    end
        // Top registers
    wire [127:0] A_top_buf1_D;
    reg  [127:0] A_top_buf1_Q;
    assign A_top_buf1_D = A[383:256];

    wire [127:0] B_top_buf1_D;
    reg  [127:0] B_top_buf1_Q;
    assign B_top_buf1_D = B[383:256];

    always @(posedge clk)
    begin
        if(~resetn) begin
            A_top_buf1_Q <= 128'd0;
            B_top_buf1_Q <= 128'd0;
        end
        else begin
            A_top_buf1_Q <= A_top_buf1_D;
            B_top_buf1_Q <= B_top_buf1_D;
        end
    end
        // Low registers
    wire            Cout1_low_buf1_D;
    reg             Cout1_low_buf1_Q;
    wire    [127:0] Res_low_buf1_D;
    reg     [127:0] Res_low_buf1_Q;
    assign {Cout1_low_buf1_D, Res_low_buf1_D} = A[127:0] + B[127:0] + Cin;
    
    always @(posedge clk)
    begin
        if(~resetn) begin
            Res_low_buf1_Q <= 128'd0;
            Cout1_low_buf1_Q <= 1'd0;
        end
        else begin
            Res_low_buf1_Q <= Res_low_buf1_D;
            Cout1_low_buf1_Q <= Cout1_low_buf1_D;
        end
    end

    // Stage 2 registers
        // Mid registers
    wire     [127:0] Res_mid_buf2_D; 
    reg      [127:0] Res_mid_buf2_Q;
    wire Cout2_mid_buf2_D;
    reg Cout2_mid_buf2_Q;

    assign {Cout2_mid_buf2_D, Res_mid_buf2_D} = A_mid_buf1_Q + B_mid_buf1_Q + Cout1_low_buf1_Q;

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
    
        // Top registers
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

    // Stage 3 registers
        // Low registers
    wire [127:0] Res_low_buf3_D;
    reg [127:0] Res_low_buf3_Q;
    assign Res_low_buf3_D = Res_low_buf2_Q;

        // Mid registers
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

        // Top registers
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

        // Output
    assign C = {Cout3_top_buf3_Q, Res_top_buf3_Q, Res_mid_buf3_Q, Res_low_buf3_Q};

    // Done signal
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

endmodule
