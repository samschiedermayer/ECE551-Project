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
logic clear_counter, clear_frequency;
logic increment;
localparam G6 = 12'd31887;  // (50 MHz / 1568)
localparam G7 = 12'd15943;  // (50 MHz / 3136)
localparam C7 = 12'd23889;  // (50 Mhz / 2093)
localparam E7 = 12'd18960;  // (50 Mhz / 2637)

///////////////////////////////////////////////////////////////
// FAST_SIM Generate Statements                             //        
/////////////////////////////////////////////////////////////
generate if(FAST_SIM) begin
    assign increment = 5'h10;
end else begin
    assign increment = 1'h01;
end

///////////////////////////////////////////////////////////////
// Duration Counter                                         //        
/////////////////////////////////////////////////////////////
always_ff @(posedge clk) begin
    if(clear_counter)
        duration_counter <= 24'b0000;
    else if(FAST_SIM)
        duration_counter <= duration_counter + increment;
end

assign done22 = duration_counter==24'h400000;
assign done23 = duration_counter==24'h800000;
assign done24 = duration_counter==24'hFFFFF;

///////////////////////////////////////////////////////////////
// Frequency Counter                                        //
/////////////////////////////////////////////////////////////
always_ff @(posedge clk) begin
    if(clear_frequency)
        frequency_counter <= 12'b0000;
    else if(FAST_SIM)
        frequency_counter <= frequency_counter + increment;
end

///////////////////////////////////////////////////////////////
// Assign output of piezo_n                                 //
/////////////////////////////////////////////////////////////
assign piezo_n = ~piezo;

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
    clear_counter = 0;
    clear_frequency = 0;
    piezo = 0;
    nxt_state = state;

    case(state)
        IDLE: begin
            if(go) begin
                clear_counter = 1;
                clear_frequency = 1;
                nxt_state = NOTE1;
            end
        end
        NOTE1: begin
            if(frequency_counter == G6)begin
                    piezo = ~piezo;
                end
            if(done23)begin
                clear_counter = 1;
                nxt_state = NOTE2;
            end
            
        end
        NOTE2: begin
            if(frequency_counter == C7)begin
                    piezo = ~piezo;
                end
            if(done23)begin
                clear_counter = 1;
                nxt_state = NOTE3;
            end
            
        end
        NOTE3: begin
            if(frequency_counter == E7)begin
                    piezo = ~piezo;
                end
            if(done23)begin
                clear_counter = 1;
                nxt_state = NOTE4_1;
            end
            
        end
        NOTE4_1: begin
            if(frequency_counter == E7)begin
                    piezo = ~piezo;
                end
            if(done23)begin
                clear_counter = 1;
                nxt_state = NOTE4_2;
            end
            
        end
        NOTE4_2: begin
            if(frequency_counter == G7)begin
                    piezo = ~piezo;
                end
            if(done23)begin
                clear_counter = 1;
                nxt_state = NOTE5;
            end
            
        end
        NOTE5: begin
            if(frequency_counter == E7)begin
                    piezo = ~piezo;
                end
            if(done22)begin
                clear_counter = 1;
                nxt_state = NOTE6;
            end
            
        end
        NOTE6: begin
            if(frequency_counter == G7)begin
                    piezo = ~piezo;
                end
            if(done24)begin
                clear_counter = 1;
                nxt_state = IDLE;
            end
            
        end
        
        default:
            nxt_state = IDLE;
    endcase
end

endmodule