module cmd_proc(
    input clk, rst_n,                   // 50MHz clock and asynch active low reset
    input [15:0] cmd,                   // command from BLE
    input cmd_rdy,                      // command ready
    output logic clr_cmd_rdy,           // mark command as consumed
    output logic send_resp,             // command finished, send_response via UART_wrapper/BT
    output logic strt_cal,              // initiate calibration of gyro
    input cal_done,                     // calibration of gyro done
    input signed [11:0] heading,        // heading from gyro
    input heading_rdy,                  // pulses high 1 clk for valid heading reading
    input lftIR,                        // nudge error +
    input cntrIR,                       // center IR reading (have I passed a line)
    input rghtIR,                       // nudge error -
    output logic signed [11:0] error,   // error to PID (heading - desired_heading)
    output logic [9:0] frwrd,           // forward speed register
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
logic move_command, move_done, frwrd_en, decrement_frwrd, increment_frwrd, clear_frwrd, zero, max_speed, old_cntrIR, cntrIR_edge;
logic [2:0] center_line_counter;
logic [3:0] number_of_squares_2x;
logic [11:0] desired_heading, error_nudge;

///////////////////////////
// frwrd Register Logic //
/////////////////////////
// Ramp-up adder //
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        frwrd <= 10'h000;
    end else if (clear_frwrd) begin
        frwrd <= 10'h000;
    end else if (frwrd_en) begin
        if (increment_frwrd) begin
            if (FAST_SIM == 1'b1) begin
                frwrd <= frwrd + 10'h020;
            end else begin
                frwrd <= frwrd + 10'h004;
            end
        end else if (decrement_frwrd) begin
            if (FAST_SIM == 1'b1) begin
                frwrd <= frwrd - 10'h040;
            end else begin
                frwrd <= frwrd - 10'h008;
            end
        end
    end
end

// Enable logic //
assign zero = ~(|frwrd);

assign max_speed = &frwrd[9:8];

assign frwrd_en = heading_rdy ? (
                        ((max_speed & increment_frwrd) | (zero & decrement_frwrd)) ? 1'b0 : 1'b1
                    ) : 1'b0;

/////////////////////////////
// Counting squares logic //
///////////////////////////
// Rise Edge Detect //
assign cntrIR_edge = ~old_cntrIR & cntrIR;

// Center line counter flip-flop //
always_ff @(posedge clk) begin
    old_cntrIR <= cntrIR;
    if (move_command) begin
        center_line_counter <= 0;
    end else if (cntrIR_edge) begin
        center_line_counter <= center_line_counter + 1'b1;
    end
end

// x2 number of squares flip-flop //
always_ff @(posedge clk) begin
    if (move_command) begin
        number_of_squares_2x <= {cmd[2:0],1'b0};
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
        if (cmd[11:4] == 8'h00) begin
            desired_heading <= 12'h000;
        end else begin
            desired_heading <= { cmd[11:4], 4'hF };
        end
    end
end

// error_nudge logic //
assign error_nudge = lftIR ? (
                        (FAST_SIM == 1'b1) ? 12'h1FF : 12'h05F
                     ) : rghtIR ? (
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
    clr_cmd_rdy = 1'b0;
    strt_cal = 1'b0;
    tour_go = 1'b0;
    fanfare_go = 1'b0;
    send_resp = 1'b0;
    move_command = 1'b0;
    clear_frwrd = 1'b0;
    increment_frwrd = 1'b0;
    decrement_frwrd = 1'b0;
    moving = 1'b0;
    
    case (state)
        CALIBRATE : begin
            if (cal_done) begin
                send_resp = 1'b1;
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
            if (move_done & (cmd[15:2] == MOVE_FANFARE_COMMAND)) begin
                fanfare_go = 1'b1;
                next_state = RAMP_DOWN;
            end else if (move_done) begin
                next_state = RAMP_DOWN;
            end else begin
                moving = 1'b1;
                increment_frwrd = 1'b1;
            end
        end
        RAMP_DOWN : begin
            if (frwrd == 10'h000) begin
                send_resp = 1'b1;
                next_state = IDLE;
            end else begin
                decrement_frwrd = 1'b1;
                moving = 1'b1;
            end
        end
        default : begin // IDLE
            if (cmd_rdy) begin
                clr_cmd_rdy = 1'b1;
                if (cmd[15:12] == CALIBRATE_COMMAND) begin
                    strt_cal = 1'b1;
                    next_state = CALIBRATE;
                end else if (cmd[15:12] == START_COMMAND) begin
                    tour_go = 1'b1;
                    next_state = IDLE;
                end else if (cmd[15:12] == MOVE_COMMAND) begin
                    move_command = 1'b1;
                    clear_frwrd = 1'b1;
                    next_state = MOVE;
                end else if (cmd[15:12] == MOVE_FANFARE_COMMAND) begin
                    move_command = 1'b1;
                    clear_frwrd = 1'b1;
                    next_state = MOVE;
                end
            end
        end
    endcase
end

endmodule
