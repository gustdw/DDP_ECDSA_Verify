module ecdsa (
    input  wire          clk,
    input  wire          resetn,
    output wire   [ 3:0] leds,

    // input registers                     // output registers
    input  wire   [31:0] rin0,             output wire   [31:0] rout0,
    input  wire   [31:0] rin1,             output wire   [31:0] rout1,
    input  wire   [31:0] rin2,             output wire   [31:0] rout2,
    input  wire   [31:0] rin3,             output wire   [31:0] rout3,
    input  wire   [31:0] rin4,             output wire   [31:0] rout4,
    input  wire   [31:0] rin5,             output wire   [31:0] rout5,
    input  wire   [31:0] rin6,             output wire   [31:0] rout6,
    input  wire   [31:0] rin7,             output wire   [31:0] rout7,

    // dma signals
    input  wire [380:0] dma_rx_data,      output wire [380:0] dma_tx_data,
    output wire [  31:0] dma_rx_address,   output wire [  31:0] dma_tx_address,
    output reg           dma_rx_start,     output reg           dma_tx_start,
    input  wire          dma_done,
    input  wire          dma_idle,
    input  wire          dma_error
  );

  // In this example three input registers are used.
  // The first one is used for giving a command to FPGA.
  // The others are for setting DMA input and output data addresses.
  wire [31:0] command;
  assign command        = rin0; // use rin0 as command
  assign dma_rx_address = rin1; // use rin1 as input  data address
  assign dma_tx_address = rin2; // use rin2 as output data address

  // Only one output register is used. It will the status of FPGA's execution.
  wire [31:0] status;
  assign rout0 = status; // use rout0 as status
  assign rout1 = 32'b0;  // not used
  assign rout2 = 32'b0;  // not used
  assign rout3 = 32'b0;  // not used
  assign rout4 = 32'b0;  // not used
  assign rout5 = 32'b0;  // not used
  assign rout6 = 32'b0;  // not used
  assign rout7 = 32'b0;  // not used


  // In this example we have only one computation command.
  wire isCmdComp = (command == 32'd1);
  wire isCmdIdle = (command == 32'd0);


  // Define state machine's states
  localparam
    STATE_IDLE     = 3'd0,
    STATE_RX       = 3'd1,
    STATE_RX_WAIT  = 3'd2,
    STATE_COMPUTE  = 3'd3,
    STATE_TX       = 3'd4,
    STATE_TX_WAIT  = 3'd5,
    STATE_DONE     = 3'd6;

  // The state machine
  reg [2:0] state = STATE_IDLE;
  reg [2:0] next_state;

  always@(*) begin
    // defaults
    next_state   <= STATE_IDLE;

    // state defined logic
    case (state)
      // Wait in IDLE state till a compute command
      STATE_IDLE: begin
        next_state <= (isCmdComp) ? STATE_RX : state;
      end

      // Wait, if dma is not idle. Otherwise, start dma operation and go to
      // next state to wait its completion.
      STATE_RX: begin
        next_state <= (~dma_idle) ? STATE_RX_WAIT : state;
      end

      // Wait the completion of dma.
      STATE_RX_WAIT : begin
        next_state <= (dma_done) ? STATE_COMPUTE : state;
      end

      // A state for dummy computation for this example. Because this
      // computation takes only single cycle, go to TX state immediately
      STATE_COMPUTE : begin
        next_state <= STATE_TX;
      end

      // Wait, if dma is not idle. Otherwise, start dma operation and go to
      // next state to wait its completion.
      STATE_TX : begin
        next_state <= (~dma_idle) ? STATE_TX_WAIT : state;
      end

      // Wait the completion of dma.
      STATE_TX_WAIT : begin
        next_state <= (dma_done) ? STATE_DONE : state;
      end

      // The command register might still be set to compute state. Hence, if
      // we go back immediately to the IDLE state, another computation will
      // start. We might go into a deadlock. So stay in this state, till CPU
      // sets the command to idle. While FPGA is in this state, it will
      // indicate the state with the status register, so that the CPU will know
      // FPGA is done with computation and waiting for the idle command.
      STATE_DONE : begin
        next_state <= (isCmdIdle) ? STATE_IDLE : state;
      end

    endcase
  end

  always@(posedge clk) begin
    dma_rx_start <= 1'b0;
    dma_tx_start <= 1'b0;
    case (state)
      STATE_RX: dma_rx_start <= 1'b1;
      STATE_TX: dma_tx_start <= 1'b1;
    endcase
  end

  // Synchronous state transitions
  always@(posedge clk)
    state <= (~resetn) ? STATE_IDLE : next_state;


  // Here is a register for the computation. Sample the dma data input in
  // STATE_RX_WAIT. Update the data with a dummy operation in STATE_COMP.
  // In this example, the dummy operation sets most-significant 32-bit to zeros.
  // Use this register also for the data output.
  
  // IMPORTANT!:
  // In your design, we only use data-transfers of 381 bits.(You may change this if you want.)
  // However, the underlying axi-stream that transfers the data uses a data size of 1024 bits.
  // We fixed this in the interfacer for you: the interfacer will put the 381 bits that you want to send to the CPU 
  // in the 381 MSB's and padd the remaining bits with zeros. 
  // Similarly, only the 381 MSB's of the 1024 bits that are received from the CPU are passed on to you in this file.
  // In the waveform, you will still see the 1024 underlying bits from which the 381 MSB's are the ones that you are working with here!
  // The software side will generate input vectors for ECDSA that already fix this padding for you.
  // IMPORTANT!
  
  reg [380:0] r_data = 381'h0;
  always@(posedge clk)
    case (state)
      STATE_RX_WAIT : r_data <= (dma_done) ? dma_rx_data : r_data;
      STATE_COMPUTE : r_data <= {32'hDEADBEEF, r_data[348:0]};
    endcase
  assign dma_tx_data = r_data;


  // Status signals to the CPU
  wire isStateIdle = (state == STATE_IDLE);
  wire isStateDone = (state == STATE_DONE);
  assign status = {29'b0, dma_error, isStateIdle, isStateDone};

endmodule
