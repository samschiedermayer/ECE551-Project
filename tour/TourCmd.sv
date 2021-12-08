module TourCmd(clk,rst_n,start_tour,move,mv_indx,
               cmd_UART,cmd,cmd_rdy_UART,cmd_rdy,
			   clr_cmd_rdy,send_resp,resp);

  input clk,rst_n;			// 50MHz clock and asynch active low reset
  input start_tour;			// from done signal from TourLogic
  input [7:0] move;			// encoded 1-hot move to perform
  output reg [4:0] mv_indx;	// "address" to access next move
  input [15:0] cmd_UART;	// cmd from UART_wrapper
  input cmd_rdy_UART;		// cmd_rdy from UART_wrapper
  output logic [15:0] cmd;		// multiplexed cmd to cmd_proc
  output cmd_rdy;			// cmd_rdy signal to cmd_proc
  input clr_cmd_rdy;		// from cmd_proc (goes to UART_wrapper too)
  input send_resp;			// lets us know cmd_proc is done with command
  output [7:0] resp;		// either 0xA5 (done) or 0x5A (in progress)

///////////////////////////////////////////////////////////////
// Signal Declaration                                       //
/////////////////////////////////////////////////////////////
logic cmd_rdy_tour, clr_cntr, increment, sel, fanfare;
logic [4:0] mv_indx_cntr;
logic [15:0] cmd_tour;

///////////////////////////////////////////////////////////////
// Muxes                                                    //
/////////////////////////////////////////////////////////////
assign cmd = sel ? cmd_tour: cmd_UART; 
assign cmd_rdy = sel ? cmd_rdy_tour: cmd_rdy_UART;

///////////////////////////////////////////////////////////////
// mv_indx counter                                          //
/////////////////////////////////////////////////////////////
always_ff @(posedge clk) begin
    if(clr_cntr)
        mv_indx_cntr <= 5'b00000;
    else if(increment)
        mv_indx_cntr <= mv_indx_cntr + 1'b1;
end

///////////////////////////////////////////////////////////////
// resp logic                                               //
/////////////////////////////////////////////////////////////
assign resp = sel ? ((mv_indx_cntr == 5'd23) ? 8'hA5: 8'h5A): 8'hA5; 
///////////////////////////////////////////////////////////////
// State Machine State Declarations                         //
/////////////////////////////////////////////////////////////
typedef enum reg [2:0] {IDLE, VERT_FORM, VERT_WAIT, HORI_FORM, HORI_WAIT} state_t;

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
   sel = 1;
   clr_cntr = 0;
   increment = 0;
   cmd_rdy_tour = 0;
   nxt_state = state;
   cmd_tour = 16'h0000;

   case(state)
      IDLE: begin
         sel = 0;
         if(start_tour)begin
            clr_cntr = 1;
            nxt_state = VERT_FORM;
         end
      end
      VERT_FORM: begin
         cmd_tour = (move & 8'h03) ? 16'h2002: //0,1 //01,02
               (move & 8'h84) ? 16'h2001: //2,7 //04,80
               (move & 8'h48) ? 16'h27F1: //3,6 //08,40
               16'h2302; //4,5 //10,20

         cmd_rdy_tour = 1;
         if(clr_cmd_rdy)
            nxt_state = VERT_WAIT;
      end
      VERT_WAIT: begin
         if(send_resp)begin
            nxt_state = HORI_FORM;
         end
      end
      HORI_FORM: begin
         cmd_tour = (move & 8'h22) ? 16'h3BF1: //1,5 //02,20
               (move & 8'hC0) ? 16'h3BF2: //6,7 //40,80
               (move & 8'h11) ? 16'h33F1: //0,4 //01,10
               16'h33F2; //2,3 //04,08
         cmd_rdy_tour = 1;
         if(clr_cmd_rdy) begin
            nxt_state = HORI_WAIT;
         end
      end
      HORI_WAIT: begin
         if(send_resp && mv_indx_cntr < 23)begin
            increment = 1;
            nxt_state = VERT_FORM;
         end
         else if (send_resp && mv_indx_cntr == 23) begin
            increment = 1;
            nxt_state = IDLE;
         end

      end
      default:
         nxt_state = IDLE;
    endcase
end
  
endmodule