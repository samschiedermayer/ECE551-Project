module charge #(
    parameter FAST_SIM = 1'b0) (
    input clk, rst_n,
    input go,
    output reg piezo, piezo_n
);
///////////////////////////////////////////////////////////////
// Parameter and Signal Declaration                         //        
/////////////////////////////////////////////////////////////
logic [24:0] duration_counter;
logic [14:0] frequency_counter;
logic clear_duration, clear_frequency, done22, done23, done24;
logic nxt_piezo;
logic [4:0] increment;
localparam G6 = 15'd31887;  // (50 MHz / 1568)
localparam G7 = 15'd15943;  // (50 MHz / 3136)
localparam C7 = 15'd23889;  // (50 Mhz / 2093)
localparam E7 = 15'd18960;  // (50 Mhz / 2637)

///////////////////////////////////////////////////////////////
// FAST_SIM Generate Statements                             //        
/////////////////////////////////////////////////////////////
generate if(FAST_SIM)
        assign increment = 5'h10;
    else 
        assign increment = 5'h01;
endgenerate

///////////////////////////////////////////////////////////////
// Duration Counter                                         //        
/////////////////////////////////////////////////////////////
always_ff @(posedge clk)
    duration_counter <= (clear_duration) ? 24'b0000 : duration_counter + increment;

assign done22 = duration_counter >= 25'h400000;
assign done23 = duration_counter >= 25'h800000;
assign done24 = duration_counter >= 25'h1000000;

///////////////////////////////////////////////////////////////
// Frequency Counter                                        //
/////////////////////////////////////////////////////////////
always_ff @(posedge clk)
    frequency_counter <= (clear_frequency) ? 15'b0000 : frequency_counter + increment;

///////////////////////////////////////////////////////////////
// Assign output of piezo_n                                 //
/////////////////////////////////////////////////////////////
assign piezo_n = ~piezo;

///////////////////////////////////////////////////////////////
// Assign piezo to nxt_piezo                                //
/////////////////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n)
    if(!rst_n)
        piezo <= 1'b0;
    else
        piezo <= nxt_piezo;

///////////////////////////////////////////////////////////////
// State Machine State Declarations                         //
/////////////////////////////////////////////////////////////
typedef enum reg [3:0] {IDLE, NOTE1, NOTE2, NOTE3, NOTE4_1, NOTE4_2, NOTE5, NOTE6} state_t;
state_t state, nxt_state;

///////////////////////////////////////////////////////////////
// State Machine Flipity Flopity                            //
/////////////////////////////////////////////////////////////
always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;

///////////////////////////////////////////////////////////////
// State Machine Output Logic                               //
/////////////////////////////////////////////////////////////
always_comb begin
    // defaulting outputs
    clear_duration = 0;
    clear_frequency = 0;
    nxt_piezo = piezo;
    nxt_state = state;

    case(state)

        IDLE: begin
            if (go) begin
                clear_duration = 1;
                clear_frequency = 1;
                nxt_state = NOTE1;
            end
        end

        NOTE1: begin
            if (frequency_counter >= G6) begin
                nxt_piezo = piezo_n;
                clear_frequency = 1;
            end
            if (done23) begin
                clear_duration = 1;
                clear_frequency = 1;
                nxt_state = NOTE2;
            end
        end

        NOTE2: begin
            if (frequency_counter >= C7) begin
                nxt_piezo = piezo_n;
                clear_frequency = 1;
            end
            if (done23) begin
                clear_duration = 1;
                clear_frequency = 1;
                nxt_state = NOTE3;
            end
        end

        NOTE3: begin
            if (frequency_counter >= E7) begin
                nxt_piezo = piezo_n;
                clear_frequency = 1;
            end
            if (done23) begin
                clear_duration = 1;
                clear_frequency = 1;
                nxt_state = NOTE4_1;
            end
        end

        NOTE4_1: begin
            if (frequency_counter >= G7) begin
                nxt_piezo = piezo_n;
                clear_frequency = 1;
            end
            if (done23) begin
                clear_duration = 1;
                clear_frequency = 1;
                nxt_state = NOTE4_2;
            end
        end

        NOTE4_2: begin
            if (frequency_counter >= G7) begin
                nxt_piezo = piezo_n;
                clear_frequency = 1;
            end
            if (done22) begin
                clear_duration = 1;
                clear_frequency = 1;
                nxt_state = NOTE5;
            end
        end

        NOTE5: begin
            if (frequency_counter >= E7) begin
                nxt_piezo = piezo_n;
                clear_frequency = 1;
            end
            if (done22) begin
                clear_duration = 1;
                clear_frequency = 1;
                nxt_state = NOTE6;
            end
        end

        NOTE6: begin
            if (frequency_counter >= G7) begin
                nxt_piezo = piezo_n;
                clear_frequency = 1;
            end
            if (done24) begin
                clear_duration = 1;
                clear_frequency = 1;
                nxt_state = IDLE;
            end
        end
        
        default:
            nxt_state = IDLE;

    endcase
end

endmodule