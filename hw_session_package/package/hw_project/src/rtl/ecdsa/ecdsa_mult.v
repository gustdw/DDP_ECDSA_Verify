module ecdsa #(parameter MAX_ARGC = 5) (
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
    output reg [  31:0] dma_rx_address,   output wire [  31:0] dma_tx_address,
    output reg           dma_rx_start,     output reg           dma_tx_start,
    input  wire          dma_done,
    input  wire          dma_idle,
    input  wire          dma_error
  );

  // In this example three input registers are used.
  // The first one is used for giving a command to FPGA.
  // The others are for setting DMA input and output data addresses.
  wire [31:0] command, addr_table_base, argc;
  assign command        = rin0; // use rin0 as command

  // Inputs use the following logic: point to a table of arguments in memory which has the inputs stored sequentially. The argument count is also provided.
  assign addr_table_base = rin1; // use rin1 as input base address of argument table
  assign argc = rin2; // use rin2 as input amount of expected arguments
  assign dma_tx_address = rin3; // use rin3 as output data address

  // Internal signals
  reg [MAX_ARGC*32-1:0] input_addr_buff; // buffer to hold all input addresses read from memory, MAX_ARGC is a random number, should be revisited after all operations are in place
  reg [MAX_ARGC*381-1:0] input_value_buff; // buffer to hold all the dereferenced input addresses.

  // Only one output register is used. It will the status of FPGA's execution.
  wire [31:0] status, result;
  assign rout0 = status; // use rout0 as status
  assign rout1 = result[31:0];  // As a test, return the least-significant 32-bits of the result
  assign rout2 = 32'b0;  // not used
  assign rout3 = 32'b0;  // not used
  assign rout4 = 32'b0;  // not used
  assign rout5 = 32'b0;  // not used
  assign rout6 = 32'b0;  // not used
  assign rout7 = 32'b0;  // not used

localparam
    CMD_MONT_MULT = 32'd1,
    CMD_EC_ADD    = 32'd2,
    CMD_IDLE     = 32'd0;

  // Command definitions
  wire isCmdMontMult = (command == CMD_MONT_MULT);
  wire isCmdECAdd    = (command == CMD_EC_ADD);
  wire isCmdIdle     = (command == CMD_IDLE);


  // Define state machine's states
  localparam
    STATE_IDLE        = 4'd0,
    STATE_LOAD_INPUT_TABLE = 4'd1,
    STATE_READ_INPUT_TABLE = 4'd2,
    STATE_LOAD_VALUE_TABLE = 4'd3,
    STATE_READ_VALUE_TABLE = 4'd4,
    STATE_COMPUTE     = 4'd5,
    STATE_TX          = 4'd6,
    STATE_TX_WAIT     = 4'd7,
    STATE_DONE        = 4'd8;

  // The state machine
  reg [3:0] state = STATE_IDLE;
  reg [3:0] next_state;

  always@(*) begin
    // state defined logic
    case (state)
      // Wait in IDLE state till a compute command
      STATE_IDLE: begin
        next_state <= (isCmdMontMult || isCmdECAdd) ? STATE_LOAD_INPUT_TABLE : state;
      end

      // Wait, if dma is not idle. Otherwise, start dma operation and go to
      // next state to wait its completion.
      STATE_LOAD_INPUT_TABLE: begin
        next_state <= (~dma_idle) ? STATE_READ_INPUT_TABLE : state;
      end

      // Wait the completion of dma.
      STATE_READ_INPUT_TABLE : begin
        //next_state <= (dma_done) ? STATE_COMPUTE : state;
        next_state <= (inputs_loaded) ? STATE_LOAD_VALUE_TABLE : state;
      end

      STATE_LOAD_VALUE_TABLE : begin
        next_state <= (~dma_idle) ? STATE_READ_VALUE_TABLE : state;
      end

      STATE_READ_VALUE_TABLE : begin
        next_state <= (inputs_loaded) ? STATE_COMPUTE : state;
      end

      // Start computation
      STATE_COMPUTE : begin
        next_state <= (mont_mult_done || ec_add_done) ? STATE_TX : state;
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

      default: begin
        next_state <= STATE_IDLE;
      end

    endcase
  end

  always@(posedge clk) begin
    dma_rx_start <= 1'b0;
    dma_tx_start <= 1'b0;
    case (state)
      STATE_LOAD_INPUT_TABLE: dma_rx_start <= 1'b1;
      STATE_LOAD_VALUE_TABLE: dma_rx_start <= 1'b1;
      STATE_TX: dma_tx_start <= 1'b1;
    endcase
  end

  // Synchronous state transitions
  always@(posedge clk)
    state <= (~resetn) ? STATE_IDLE : next_state;


  // Here is a register for the computation.
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

  reg [3:0] counter;
  wire inputs_loaded;
  assign inputs_loaded = (counter == argc);

  // Sample DMA outputs and capture read flags. Add reset behavior so flags
  // start in a known state after reset.
  always@(posedge clk) begin
    if (~resetn) begin
      r_data <= 381'h0;
    end else begin
      case (state)
        STATE_LOAD_INPUT_TABLE : begin
          input_addr_buff <= 0;
          dma_rx_address <= addr_table_base;
          counter <= 0;
        end

        // Load in each address of the inputarguments into the input_values_buffer. 
        // After this, argc input arguments should be loaded in.
        // Goes to next state when inputs_loaded (= (counter==argc)) == 1
        STATE_READ_INPUT_TABLE : begin
          dma_rx_address <= addr_table_base + offset_32;
          input_addr_buff[offset_32+31 -: 31] <= (dma_done) ? dma_rx_data : input_addr_buff[offset_32+31 -: 31];
          counter = (dma_done) ? counter + 1 : counter; // blocking, should only update after values are loaded in
        end

        STATE_LOAD_VALUE_TABLE: begin
          input_value_buff <= 0;
          dma_rx_address <= input_addr_buff[31:0];
          counter <= 0;
        end

        STATE_READ_VALUE_TABLE: begin
          dma_rx_address <= input_addr_buff[offset_32+31 -: 31];
          input_value_buff[offset_381+380 -: 380] <= (dma_done) ? dma_rx_data : input_value_buff[offset_381+380 -: 380];
          counter = (dma_done) ? counter + 1 : counter; // blocking, should only update after values are loaded in
        end

        STATE_COMPUTE : begin
          r_data <= 0;
          case (command)
            CMD_MONT_MULT: r_data <= (mont_mult_done) ? mont_mult_result : r_data;
            CMD_EC_ADD: r_data <= (ec_add_done) ? ec_add_result : r_data;
            // CMD_EC_MULT: r_data <= (ec_mult_done) ? ec_mult_result : r_data;
          endcase
        end
        default: begin
          // hold values
        end
      endcase
    end
  end
  assign dma_tx_data = r_data;


  // Status signals to the CPU
  wire isStateIdle = (state == STATE_IDLE);
  wire isStateDone = (state == STATE_DONE);
  assign status = {29'b0, dma_error, isStateIdle, isStateDone};
  
  assign leds = state; // for debugging: show current state on leds

  reg [31:0] offset_32, offset_381;
  always @(posedge counter[0], negedge counter[0]) begin
    if (~resetn) begin
      offset_32 <= 0;
      offset_381 <= 0;
    end else begin
      offset_32 <= offset_32 + 32;
      offset_381 <= offset_381 + 381;
    end
  end


  // Multiplier
  wire mont_mult_start, mont_mult_done;
  wire [38:0] mont_mult_result;
  assign mont_mult_start = (state == STATE_COMPUTE && isCmdMontMult);
  assign mont_mult_a = input_value_buff[380 : 0];
  assign mont_mult_b = input_value_buff[2*381-1 : 381];
  assign mont_mult_m = input_value_buff[3*381-1 : 2*381];
  montgomery montgomery_instance (
    .clk (clk),
    .resetn (resetn),
    .start (mont_mult_start),
    .in_a (mont_mult_a),
    .in_b (mont_mult_b),
    .in_m (mont_mult_m),
    .done (mont_mult_done),
    .result (mont_mult_result)
  );

  // EC Addition
  wire ec_add_start, ec_add_done;
  reg [380:0] ec_add_result;
endmodule
