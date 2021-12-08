module cmd_proc(
    input clk, rst_n,                   // 50MHz clock and asynch active low reset
    input [15:0] command,               // command from BLE
    input command_ready,                // command ready
    output logic clear_command_ready,   // mark command as consumed
    output logic send_response,         // command finished, send_response via UART_wrapper/BT
    output logic start_calibration,     // initiate calibration of gyro
    input calibration_done,             // calibration of gyro done
    input signed [11:0] heading,        // heading from gyro
    input heading_ready,                // pulses high 1 clk for valid heading reading
    input leftIR,                       // nudge error +
    input centerIR,                     // center IR reading (have I passed a line)
    input rightIR,                      // nudge error -
    output logic signed [11:0] error,   // error to PID (heading - desired_heading)
    output logic [9:0] forward,         // forward speed register
    output logic moving,                // asserted when moving (allows yaw integration)
    output logic tour_go,               // pulse to initiate TourCmd block
    output logic fanfare_go             // kick off the "Charge!" fanfare on piezo
);

parameter FAST_SIM = 1;
localparam CALIBRATE_COMMAND = 4'b0000;
localparam MOVE_COMMAND = 4'b0010;
localparam MOVE_FANFARE_COMMAND = 4'b0011;
localparam START_COMMAND = 4'b0100;

//////////////////////////////
// Define internal signals //
////////////////////////////
logic move_command, forward_en, decrement_forward, increment_forward, clear_forward, zero, max_speed, old_centerIR, centerIR_edge;
logic [2:0] center_line_counter;
logic [3:0] number_of_squares_2x;
logic [11:0] desired_heading, error_nudge;

///////////////////////////
// frwrd Register Logic //
/////////////////////////
// Ramp-up adder //
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        forward <= 10'h000;
    end else if (clear_forward) begin
        forward <= 10'h000;
    end else if (forward_en) begin
        if (increment_forward) begin
            if (FAST_SIM == 1'b1) begin
                forward <= forward + 10'h020;
            end else begin
                forward <= forward + 10'h004;
            end
        end else if (decrement_forward) begin
            if (FAST_SIM == 1'b1) begin
                forward <= forward - 10'h040;
            end else begin
                forward <= forward - 10'h008;
            end
        end
    end
end

// Enable logic //
assign zero = ~(|forward);

assign max_speed = &forward[9:8];

assign forward_en = heading_ready ? (
                        ((max_speed & increment_forward) | (zero & decrement_forward)) ? 1'b0 : 1'b1
                    ) : 1'b0;

/////////////////////////////
// Counting squares logic //
///////////////////////////
// Rise Edge Detect //
assign centerIR_edge = ~old_centerIR & centerIR;

// Center line counter flip-flop //
always_ff @(posedge clk) begin
    old_centerIR <= centerIR;
    if (move_command) begin
        center_line_counter <= 0;
    end else if (centerIR_edge) begin
        center_line_counter <= center_line_counter + 1'b1;
    end
end

// x2 number of squares flip-flop //
always_ff @(posedge clk) begin
    if (move_command) begin
        number_of_squares_2x <= {command[2:0],1'b0};
    end
end

// move_done logic //
assign move_done = number_of_squares_2x == center_line_counter;

//////////////////////////
// PID interface logic //
////////////////////////
// desired_heading flip-flop //
always_ff @(posedge clk) begin
    if (move_command) begin
        if (command[11:4] == 8'h00) begin
            desired_heading <= 12'h000;
        end else begin
            desired_heading <= { command[11:4], 4'hF };
        end
    end
end

// error_nudge logic //
assign error_nudge = leftIR ? (
                        (FAST_SIM == 1'b1) ? 12'h1FF : 12'h05F
                     ) : rightIR ? (
                        (FAST_SIM == 1'b1) ? 12'hE00 : 12'hFA1
                     ) : 12'h000;

// error logic //
assign error = heading - desired_heading + error_nudge;


//////////////////////////////////
// State Machine Control Logic //
////////////////////////////////

// Define state as enumerated type //
typedef enum reg [2:0] { IDLE, CALIBRATE, MOVE, RAMP_UP, RAMP_DOWN } state_t;
state_t state, next_state;

// Infer state flop next //
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    state <= IDLE;
  end else begin
    state <= next_state;
  end
end

// State Machine //
always_comb begin
    // Default values
    next_state = state;
    clear_command_ready = 1'b0;
    start_calibration = 1'b0;
    tour_go = 1'b0;
    fanfare_go = 1'b0;
    send_response = 1'b0;
    move_command = 1'b0;
    clear_forward = 1'b0;
    increment_forward = 1'b0;
    decrement_forward = 1'b0;
    moving = 1'b0;
    
    case (state)
        CALIBRATE : begin
            if (calibration_done) begin
                send_response = 1'b1;
                next_state = IDLE;
            end
        end
        MOVE : begin
            if ((error < 12'h030) | (error > 12'hFD0)) begin
                moving = 1'b1;
                next_state = RAMP_UP;
            end
        end
        RAMP_UP : begin
            if (move_done & (command[15:2] == MOVE_FANFARE_COMMAND)) begin
                fanfare_go = 1'b1;
                next_state = RAMP_DOWN;
            end else if (move_done) begin
                next_state = RAMP_DOWN;
            end else begin
                moving = 1'b1;
                increment_forward = 1'b1;
            end
        end
        RAMP_DOWN : begin
            if (forward == 10'h000) begin
                send_response = 1'b1;
                next_state = IDLE;
            end else begin
                decrement_forward = 1'b1;
                moving = 1'b1;
            end
        end
        default : begin // IDLE
            if (command_ready) begin
                clear_command_ready = 1'b1;
                if (command[15:12] == CALIBRATE_COMMAND) begin
                    start_calibration = 1'b1;
                    next_state = CALIBRATE;
                end else if (command[15:12] == START_COMMAND) begin
                    tour_go = 1'b1;
                    next_state = IDLE;
                end else if (command[15:12] == MOVE_COMMAND) begin
                    move_command = 1'b1;
                    clear_forward = 1'b1;
                    next_state = MOVE;
                end else if (command[15:12] == MOVE_FANFARE_COMMAND) begin
                    move_command = 1'b1;
                    clear_forward = 1'b1;
                    next_state = MOVE;
                end
            end
        end
    endcase
end

endmodule