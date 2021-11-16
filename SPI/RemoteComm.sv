module RemoteComm(clk, rst_n, RX, TX, cmd, snd_cmd, cmd_snt, resp_rdy, resp);

input clk, rst_n;		// clock and active low reset
input RX;				// serial data input
input snd_cmd;			// indicates to tranmit 24-bit command (cmd)
input [15:0] cmd;		// 16-bit command

output TX;				// serial data output
output reg cmd_snt;		// indicates transmission of command complete
output resp_rdy;		// indicates 8-bit response has been received
output [7:0] resp;		// 8-bit response from DUT

wire [7:0] tx_data;		// 8-bit data to send to UART
wire tx_done;			// indicates 8-bit was sent over UART
wire rx_rdy;			// indicates 8-bit response is ready from UART

///////////////////////////////////////////////////////////////
// Internal Signals Declarations                            //
/////////////////////////////////////////////////////////////
logic sel_high, set_cmd_snt, trmt;

///////////////////////////////////////////////////////////////
// Flipity Flopity and reg to buffer low but of cmd                 //
/////////////////////////////////////////////////////////////
reg [7:0] flipity_flopity_cmd_low;

always_ff @(posedge clk) begin
    if(snd_cmd)
        flipity_flopity_cmd_low <= cmd[7:0];
    
end

///////////////////////////////////////////////////////////////
// Mux for switching the byte of data to be transmitted     //
/////////////////////////////////////////////////////////////
assign tx_data = sel_high ? cmd[15:8]:
                flipity_flopity_cmd_low;


///////////////////////////////////////////////////////////////
// Reset Logic for cmd_snt with flipity flopity             //
/////////////////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
        cmd_snt <= 0;
    else if(snd_cmd)
        cmd_snt <= 0;
    else if(set_cmd_snt)
        cmd_snt <= 1;
end

///////////////////////////////////////////////////////////////
// State Declarations for State Machine                     //
/////////////////////////////////////////////////////////////
typedef enum reg [1:0] {IDLE, HIGH, LOW} state_t;
state_t state, nxt_state;

///////////////////////////////////////////////////////////////
// Instantiate basic 8-bit UART transceiver                 //
/////////////////////////////////////////////////////////////
UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(tx_data), .trmt(trmt),
           .tx_done(tx_done), .rx_data(resp), .rx_rdy(resp_rdy), .clr_rx_rdy(resp_rdy));
		   
//////////////////////////////////////////////////////////////
// State Machine State Flipity Flopity                      //
/////////////////////////////////////////////////////////////
always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;

///////////////////////////////////////////////////////////////
// Sstate Machine Logic                                     //
/////////////////////////////////////////////////////////////
always_comb begin
    // defaulting outputs
    sel_high = 1;
    set_cmd_snt = 0;
    trmt = 0;
    nxt_state = state; // default the nxt_state to the current state

    case(state)
        IDLE: if(snd_cmd) begin
            trmt = 1;
            nxt_state = HIGH;
        end
        HIGH: 
        if(tx_done) begin
            sel_high = 0;
            trmt = 1;
            nxt_state = LOW;
        end 
        LOW: if(tx_done) begin
            set_cmd_snt = 1;
            nxt_state = IDLE;
        end
        default:
            nxt_state = IDLE;
    endcase
end

endmodule	
