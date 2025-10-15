`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 08/22/2018 10:43:00 AM
// Design Name:
// Module Name: tb_adder
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

`define RESET_TIME 25
`define CLK_PERIOD 10
`define CLK_HALF 5

module tb_warmup2_adder();

    // Define internal regs and wires
    reg          clk;
    reg          resetn;
    reg          start;
    reg          Cin;
    reg  [383:0] inA;
    reg  [383:0] inB;
    wire [384:0] outC;
    reg  [384:0] result;
    wire         done;
    reg          done_expected;
    wire         resultOk;   

    assign resultOk = ((outC == result) && (done == done_expected));          

    warmup2_adder dut(
        clk,
        resetn,
        start,
        Cin,
        inA,
        inB,
        outC,
        done);

    // Generate Clock
    initial begin
        clk = 0;
        forever #`CLK_HALF clk = ~clk;
    end

    // INPUTS
    initial begin
        resetn <= 1'b0;
        start  <= 1'b0;
        Cin    <= 1'h0;
        inA    <= 384'h0;
        inB    <= 384'h0;

        #`RESET_TIME

        resetn <= 1'b1;
        start  <= 1'b1;
        Cin    <= 1'h0;
        inA    <= 384'h0;
        inB    <= 384'h0;

        #`CLK_PERIOD;
        
        start  <= 1'b1;
        Cin    <= 1'h0;
        inA    <= 384'h975ee79c61f1fccbdabe75336fcfda3b028c6e9346c8b8f0170393175672606969f6c184d9ef0b8b648ef548030b7b49;
        inB    <= 384'hccc688532f469ab67fe88f21ef64c0ce787d08cb81aca849d7af1a3afacbd54d4a54d77d178dc0d1dda357cfca70c543;

        #`CLK_PERIOD;
        
        start  <= 1'b1;
        Cin    <= 1'h0;
        inA    <= 384'ha58b494b7a1cb626b9a3235d688d9c071055a8217df4132952b674c6170f70448c21029586e210a2db7f0d853d854a48;
        inB    <= 384'h9e841c2da11f33f9b939b0fdff846d66c060cb66fdf82d6aaabc942613f0dc4287f172f0591ee0467fc38edaae8bc99e;

        #`CLK_PERIOD;
        
        start  <= 1'b1;
        Cin    <= 1'h1;
        inA    <= 384'ha89b69dde683384b315ab2e1a934d8a3ef3c9503a4f37fb51ce9f6527e612bc1cbe6c5c0f35544fdbf703dfcd5d04eec;
        inB    <= 384'ha3316ac1a2780aaf9f780569b54ecef597ee0d25ffd19b40313ae53942c2c0324b25dbb7c9e266f94f0dfa50762b7315;

        #`CLK_PERIOD;
        start  <= 1'b0;
    end

    // CHECK OUTPUTS
    initial begin
        result = 385'h0;
        done_expected = 1'b0;
        // Copy delays before we start computations by raising resetn to high
        #`RESET_TIME

        // Start of computation, now delay as long as the dut
        #`CLK_PERIOD;
        #`CLK_PERIOD;
        #`CLK_PERIOD;

        // We expect the first output now
        result = 385'h0;
        done_expected = 1'b1;
        #`CLK_PERIOD;
        // The second output now
        result = 385'h164256fef913897825aa704555f349b097b09775ec8756139eeb2ad52513e35b6b44b9901f17ccc5d42324d17cd7c408c;
        done_expected = 1'b1;
        #`CLK_PERIOD;
        // And so on...
        result = 385'h1440f65791b3bea2072dcd45b6812096dd0b673887bec4093fd7308ec2b004c8714127585e000f0e95b429c5fec1113e6;
        done_expected = 1'b1;
        #`CLK_PERIOD;

        result = 385'h14bccd49f88fb42fad0d2b84b5e83a799872aa229a4c51af54e24db8bc123ebf4170ca178bd37abf70e7e384d4bfbc202;
        done_expected = 1'b1;
        #`CLK_PERIOD;

        done_expected = 1'b0;
        #`CLK_PERIOD;
        #`CLK_PERIOD;
        #`CLK_PERIOD;
        #`CLK_PERIOD;
        $finish;
    end

endmodule
