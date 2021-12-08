module UART_wrapper(
    input clk,
    input rst_n,
    input clr_cmd_rdy,
    input trmt,
    input [7:0] resp,
    input RX,
    output reg cmd_rdy,
    output [15:0] cmd,
    output tx_done,
    output TX
);

///////////////////////////////////////////////////////////////
// Internal Signal Declaration                              //
/////////////////////////////////////////////////////////////
logic cmd_sel, clr_rx_rdy, set_cmd_rdy, rx_rdy;
reg [7:0] high_cmd, rx_data;

///////////////////////////////////////////////////////////////
// State Machine Logic                                      //
/////////////////////////////////////////////////////////////
UART iDUT(.clk(clk), .rst_n(rst_n), .RX(RX),.TX(TX), .rx_rdy(rx_rdy), .clr_rx_rdy(clr_rx_rdy), .rx_data(rx_data), .trmt(trmt), .tx_data(resp), .tx_done(tx_done));

///////////////////////////////////////////////////////////////
// cmd flipity flopity (intentionally infered register)     //
/////////////////////////////////////////////////////////////
always_ff @(posedge clk)begin
    if(cmd_sel)
        high_cmd <= rx_data;   
end

///////////////////////////////////////////////////////////////
// cmd merge of high bits of cmd and low bits of cmd        //
/////////////////////////////////////////////////////////////
assign cmd[15:8] = high_cmd;
assign cmd[7:0] = rx_data;

///////////////////////////////////////////////////////////////
// cmd_rdy flipity flopity                                  //
/////////////////////////////////////////////////////////////
always_ff@(posedge clk)begin
    if(!rst_n)
        cmd_rdy <= 0;
    else if(set_cmd_rdy)
        cmd_rdy <= 1;
    else if(clr_cmd_rdy || rx_rdy)
        cmd_rdy <= 0;
end

///////////////////////////////////////////////////////////////
// State Machine Type Declaration                           //
/////////////////////////////////////////////////////////////
typedef enum reg {IDLE, RDY} state_t;
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
// State Machine Logic                                      //
/////////////////////////////////////////////////////////////
always_comb begin
    // defaulting outputs
    cmd_sel = 1'b0;
    clr_rx_rdy = 1'b0;
    set_cmd_rdy = 1'b0;
    nxt_state = state;

    case(state)
        IDLE: 
            if(rx_rdy) begin
                clr_rx_rdy = 1'b1;
                cmd_sel = 1'b1;
                nxt_state = RDY;
            end
        RDY: 
            if(rx_rdy)begin
                set_cmd_rdy = 1'b1;
                clr_rx_rdy = 1'b1;
                nxt_state = IDLE;
            end
        default:
            nxt_state = IDLE;
    endcase
end

endmodule