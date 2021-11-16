module charge(
    input clk, rst_n,
    input go,
    output piezo, piezo_n
);
///////////////////////////////////////////////////////////////
// Parameter and Signal Declaration                         //        
/////////////////////////////////////////////////////////////
parameter FAST_SIM = 1'b1;
logic [23:0] bit_counter;
logic [11:0] frequency_counter;
logic clear_counter;

///////////////////////////////////////////////////////////////
// Duration Counter                                         //        
/////////////////////////////////////////////////////////////
always_ff @(posedge clk) begin
    if(clear_counter)
        duration_counter <= 24'b0000;
    else
        duration_counter <= duration_counter + 1;
end

assign done22 = FAST_SIM ? duration_counter==24'h40000: duration_counter==24'h400000;
assign done23 = FAST_SIM ? duration_counter==24'h80000: duration_counter==24'h800000;
assign done24 = FAST_SIM ? duration_counter==24'hFFFF: duration_counter==24'hFFFFF;

///////////////////////////////////////////////////////////////
// Frequency Counter                                        //
/////////////////////////////////////////////////////////////
always_ff @(posedge clk) begin
    if(clear_counter)
        frequency_counter <= 12'b0000;
    else
        frequency_counter <= frequency_counter + 1;
end

///////////////////////////////////////////////////////////////
// FAST_SIM logic for Note Frequency                        //
/////////////////////////////////////////////////////////////
assign G6 = FAST_SIM ? frequency_counter==(12'd1568/12'd16): frequency_counter== 12'd1568;
assign G7 = FAST_SIM ? frequency_counter==(12'd3136/12'd16): frequency_counter== 12'd3136;
assign C7 = FAST_SIM ? frequency_counter==(12'd2093/12'd16): frequency_counter== 12'd2093;
assign E7 = FAST_SIM ? frequency_counter==(12'd2637/12'd16): frequency_counter== 12'd2637;

///////////////////////////////////////////////////////////////
// Assign output of piezo_n                                 //
/////////////////////////////////////////////////////////////
assign piezo_n = ~piezo;

///////////////////////////////////////////////////////////////
// State Machine State Declarations                         //
/////////////////////////////////////////////////////////////
typedef enum reg [1:0] {IDLE, FP, TRANS, BP} state_t;
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
    clear_counter = 1;
    nxt_state = state;

    case(state)
        IDLE: begin
            ld_SCLK = 1;
            if(go) begin
                clear counter = 1;
                nxt_state = FP;
            end
        end
        G6: begin
            
        end
        
        
        default:
            nxt_state = IDLE;
    endcase
end

endmodule