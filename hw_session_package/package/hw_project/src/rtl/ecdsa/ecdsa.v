module ecdsa #(parameter MAX_ARGC_I = 7, parameter MAX_ARGC_O = 3) (
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
    output reg  [ 31:0] dma_rx_address,   output reg  [ 31:0] dma_tx_address,
    output reg           dma_rx_start,     output reg           dma_tx_start,
    input  wire          dma_done,
    input  wire          dma_idle,
    input  wire          dma_error
  );

  // In this example three input registers are used.
  // The first one is used for giving a command to FPGA.
  // The others are for setting DMA input and output data addresses.
  wire [31:0] command, addr_table_base_i, argc_i, addr_table_base_o, argc_o;
  assign command        = rin0; // use rin0 as command

  // Inputs use the following logic: point to a table of arguments in memory which has the inputs stored sequentially. The argument count is also provided.
  assign addr_table_base_i = rin1; // use rin1 as input base address of argument table
  assign argc_i = rin2; // use rin2 as input amount of expected arguments
  assign addr_table_base_o = rin3; // use rin3 as output data address
  assign argc_o = rin4; // use rin4 as output data address

  // Internal signals
  reg [MAX_ARGC_I*32-1:0] input_addr_buff; // buffer to hold all input addresses read from memory, MAX_ARGC_I is a random number, should be revisited after all operations are in place
  reg [MAX_ARGC_I*381-1:0] input_value_buff; // buffer to hold all the dereferenced input addresses.

  reg [MAX_ARGC_O*32-1:0] output_addr_buff; // buffer to hold all output addresses read from memory

  // Only one output register is used. It will the status of FPGA's execution.
  wire [31:0] status;
  assign rout0 = status; // use rout0 as status --- IGNORE ---
  assign rout1 = 0;
  assign rout2 = 0;
  assign rout3 = 0;
  assign rout4 = 0;
  assign rout5 = 0;
  assign rout6 = 0;
  assign rout7 = 0;


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
    STATE_WAIT_INPUT_TABLE = 4'd2,
    STATE_READ_INPUT_TABLE = 4'd3,
    STATE_LOAD_VALUE_TABLE = 4'd4,
    STATE_WAIT_VALUE_TABLE = 4'd5,
    STATE_READ_VALUE_TABLE = 4'd6,
    STATE_COMPUTE     = 4'd7,
    STATE_LOAD_OUTPUT_TABLE = 4'd8,
    STATE_WAIT_OUTPUT_TABLE = 4'd9,
    STATE_READ_OUTPUT_TABLE = 4'd10,
    STATE_TX          = 4'd11,
    STATE_TX_WAIT     = 4'd12,
    STATE_TX_UPDATE   = 4'd13,
    STATE_DONE        = 4'd14;

  // The state machine
  reg [3:0] state = STATE_IDLE;
  reg [3:0] next_state;
  
  reg [3:0] counter;
  wire inputs_loaded, outputs_written, computation_done;
  assign inputs_loaded = (counter == argc_i - 1);
  assign outputs_written = (counter == argc_o - 1);
  assign computation_done = (isCmdMontMult) ? mont_mult_done :
                            (isCmdECAdd)    ? ec_add_done :
                            1'b0;
  
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
        next_state <= (~dma_idle) ? STATE_WAIT_INPUT_TABLE : state;
      end

      STATE_WAIT_INPUT_TABLE : begin
        next_state <= (dma_done) ? STATE_READ_INPUT_TABLE : state;
      end

      // Wait the completion of dma.
      STATE_READ_INPUT_TABLE : begin
        next_state <= STATE_LOAD_VALUE_TABLE;
      end

      STATE_LOAD_VALUE_TABLE : begin
        next_state <= (~dma_idle) ? STATE_WAIT_VALUE_TABLE : state;
      end
      
      STATE_WAIT_VALUE_TABLE : begin
        next_state <= (dma_done) ? STATE_READ_VALUE_TABLE : state;
      end

      STATE_READ_VALUE_TABLE : begin
        next_state <= (inputs_loaded) ? STATE_COMPUTE : STATE_LOAD_VALUE_TABLE;
      end

      // Start computation
      STATE_COMPUTE : begin
        next_state <= (computation_done) ? STATE_LOAD_OUTPUT_TABLE : state;
      end

      STATE_LOAD_OUTPUT_TABLE : begin
        next_state <= (~dma_idle) ? STATE_WAIT_OUTPUT_TABLE : state;
      end

      STATE_WAIT_OUTPUT_TABLE : begin
        next_state <= (dma_done) ? STATE_READ_OUTPUT_TABLE : state;
      end

      STATE_READ_OUTPUT_TABLE : begin
        next_state <= STATE_TX;
      end

      // Wait, if dma is not idle. Otherwise, start dma operation and go to
      // next state to wait its completion.
      STATE_TX : begin
        next_state <= (~dma_idle) ? STATE_TX_WAIT : state;
      end

      // Wait the completion of dma.
      STATE_TX_WAIT : begin
        next_state <= (dma_done) ? STATE_TX_UPDATE : state;
      end

      // 
      STATE_TX_UPDATE : begin
        next_state <= (outputs_written) ? STATE_DONE : STATE_TX;
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
      STATE_LOAD_OUTPUT_TABLE: dma_rx_start <= 1'b1;
      STATE_TX: dma_tx_start <= 1'b1;
    endcase
  end

  // Synchronous state transitions
  always@(posedge clk)
    state <= (~resetn) ? STATE_IDLE : next_state;


  // Here is a register for the computation.
  // Use this register also for the data output.
  reg [380:0] r_data;
  
  // IMPORTANT!:
  // In your design, we only use data-transfers of 381 bits.(You may change this if you want.)
  // However, the underlying axi-stream that transfers the data uses a data size of 1024 bits.
  // We fixed this in the interfacer for you: the interfacer will put the 381 bits that you want to send to the CPU 
  // in the 381 MSB's and padd the remaining bits with zeros. 
  // Similarly, only the 381 MSB's of the 1024 bits that are received from the CPU are passed on to you in this file.
  // In the waveform, you will still see the 1024 underlying bits from which the 381 MSB's are the ones that you are working with here!
  // The software side will generate input vectors for ECDSA that already fix this padding for you.
  // IMPORTANT!
  

  // Sample DMA outputs and capture read flags. Add reset behavior so flags
  // start in a known state after reset.
  always@(posedge clk) begin
    if (~resetn) begin
      counter <= 0;
    end else begin
      case (state)
        STATE_IDLE : begin
          counter <= 0;
        end

        STATE_LOAD_INPUT_TABLE : begin
          dma_rx_address <= addr_table_base_i;
        end

        STATE_WAIT_INPUT_TABLE : begin
          input_addr_buff[MAX_ARGC_I*32-1 -: MAX_ARGC_I*32] <= (dma_done) ? dma_rx_data[380 -: MAX_ARGC_I*32] : input_addr_buff[MAX_ARGC_I*32-1 -: MAX_ARGC_I*32];
        end

        STATE_READ_INPUT_TABLE : begin
        end

        STATE_LOAD_VALUE_TABLE: begin
          // Explicit MUX based on counter
          case (counter)
              0: dma_rx_address <= input_addr_buff[((MAX_ARGC_I-0)*32 - 1) -: 32];
              1: dma_rx_address <= input_addr_buff[((MAX_ARGC_I-1)*32 - 1) -: 32];
              2: dma_rx_address <= input_addr_buff[((MAX_ARGC_I-2)*32 - 1) -: 32];
              3: dma_rx_address <= input_addr_buff[((MAX_ARGC_I-3)*32 - 1) -: 32];
              4: dma_rx_address <= input_addr_buff[((MAX_ARGC_I-4)*32 - 1) -: 32];
              5: dma_rx_address <= input_addr_buff[((MAX_ARGC_I-5)*32 - 1) -: 32];
              6: dma_rx_address <= input_addr_buff[((MAX_ARGC_I-6)*32 - 1) -: 32];
              default: dma_rx_address <= 32'h0;
          endcase
      end

      STATE_WAIT_VALUE_TABLE : begin
          if (dma_done) begin
              // Explicit write enable based on counter
              case (counter)
                  0: input_value_buff[380:0]     <= dma_rx_data[380:0];
                  1: input_value_buff[761:381]   <= dma_rx_data[380:0];
                  2: input_value_buff[1142:762]  <= dma_rx_data[380:0];
                  3: input_value_buff[1523:1143] <= dma_rx_data[380:0];
                  4: input_value_buff[1904:1524] <= dma_rx_data[380:0];
                  5: input_value_buff[2285:1905] <= dma_rx_data[380:0];
                  6: input_value_buff[2666:2286] <= dma_rx_data[380:0];
                  default: ;
              endcase
          end
      end

        STATE_READ_VALUE_TABLE: begin
          counter <= counter + 1;
        end

        STATE_COMPUTE : begin
          case (command)
            CMD_MONT_MULT: r_data <= (mont_mult_done) ? mont_mult_result : r_data;
            CMD_EC_ADD: r_data <= (ec_add_done) ? ec_add_Xr : r_data;
          endcase
        end

        STATE_LOAD_OUTPUT_TABLE : begin
          dma_rx_address <= addr_table_base_o;
        end

        STATE_WAIT_OUTPUT_TABLE : begin
          output_addr_buff[MAX_ARGC_O*32-1 -: MAX_ARGC_O*32] <= (dma_done) ? dma_rx_data[380 -: MAX_ARGC_O*32] : output_addr_buff[MAX_ARGC_O*32-1 -: MAX_ARGC_O*32];
        end

        STATE_READ_OUTPUT_TABLE : begin
        end
        
        STATE_TX: begin
          case (counter)
            0: begin 
              dma_tx_address <= output_addr_buff[((MAX_ARGC_O - 0)*32 - 1) -: 32];
            end
            1: begin
              dma_tx_address <= output_addr_buff[((MAX_ARGC_O - 1)*32 - 1) -: 32];
            end
            2: begin
              dma_tx_address <= output_addr_buff[((MAX_ARGC_O - 2)*32 - 1) -: 32];
            end
            default: dma_tx_address <= 32'h0;
          endcase
        end

        STATE_TX_WAIT: begin
        end

        STATE_TX_UPDATE: begin
          counter <= counter + 1;
          case (command)
            CMD_EC_ADD:
              case (counter)
                0: r_data <= ec_add_Xr;
                1: r_data <= ec_add_Yr;
                2: r_data <= ec_add_Zr;
              endcase
          endcase
        end

        default: begin
        end
      endcase
      // Handle the counter reset between the two loops specifically:
      // If we are finishing READ_INPUT and moving to LOAD_VALUE, we must reset counter/offsets.
      if ((state == STATE_READ_INPUT_TABLE || state == STATE_READ_VALUE_TABLE) && counter == argc_i - 1) begin
          counter <= 0;
      end
    end
  end
  assign dma_tx_data = r_data;

  // Status signals to the CPU
  wire isStateIdle = (state == STATE_IDLE);
  wire isStateDone = (state == STATE_DONE);
  assign status = {29'b0, dma_error, isStateIdle, isStateDone};
  
  // --- ECDSA OPERATIONS INSTANCES ---
  // Multiplier
  wire mont_mult_start, mont_mult_done;
  reg mont_mult_start_reg;
  always @(posedge clk) begin
    case (state)
      STATE_IDLE: mont_mult_start_reg <= 1'b0;
      STATE_READ_VALUE_TABLE: mont_mult_start_reg <= 1'b1 && inputs_loaded;
      STATE_COMPUTE: mont_mult_start_reg <= 1'b0;
    endcase
  end
  wire [380:0] mont_mult_result, mont_mult_a, mont_mult_b, mont_mult_m;
  assign mont_mult_start = (state == STATE_COMPUTE && isCmdMontMult);
  assign mont_mult_a = input_value_buff[380 : 0];
  assign mont_mult_b = input_value_buff[2*381-1 : 381];
  assign mont_mult_m = input_value_buff[3*381-1 : 2*381];
  // montgomery montgomery_instance (
  //   .clk (clk),
  //   .resetn (resetn),
  //   .start (mont_mult_start),
  //   .in_a (mont_mult_a),
  //   .in_b (mont_mult_b),
  //   .in_m (mont_mult_m),
  //   .done (mont_mult_done),
  //   .result (mont_mult_result)
  // );

  mont montgomery_willem (
    .clk (clk),
    .resetn (resetn),
    .start (mont_mult_start_reg),
    .in_a (mont_mult_a),
    .in_b (mont_mult_b),
    .in_m (mont_mult_m),
    .done (mont_mult_done),
    .result (mont_mult_result)
  );

  // EC Addition
  wire ec_add_start, ec_add_done;
  assign ec_add_start = (state == STATE_COMPUTE && isCmdECAdd);

  wire [380:0] ec_add_Xp, ec_add_Yp, ec_add_Zp;
  assign ec_add_Xp = input_value_buff[1*381-1 -: 381];
  assign ec_add_Yp = input_value_buff[2*381-1 -: 381];
  assign ec_add_Zp = input_value_buff[3*381-1 -: 381];

  wire [380:0] ec_add_Xq, ec_add_Yq, ec_add_Zq;
  assign ec_add_Xq = input_value_buff[4*381-1 -: 381];
  assign ec_add_Yq = input_value_buff[5*381-1 -: 381];
  assign ec_add_Zq = input_value_buff[6*381-1 -: 381];

  wire [380:0] ec_add_M;
  assign ec_add_M = input_value_buff[7*381-1 -: 381];

  wire [380:0] ec_add_Xr, ec_add_Yr, ec_add_Zr;
  EC_adder ec_adder_inst (
    .clk(clk),
    .resetn(resetn),
    .start(ec_add_start),
    .Xp(ec_add_Xp),
    .Yp(ec_add_Yp),
    .Zp(ec_add_Zp),
    .Xq(ec_add_Xq),
    .Yq(ec_add_Yq),
    .Zq(ec_add_Zq),
    .M(ec_add_M),
    .Xr(ec_add_Xr),
    .Yr(ec_add_Yr),
    .Zr(ec_add_Zr),
    .done(ec_add_done)
);
endmodule
// EC point addition module