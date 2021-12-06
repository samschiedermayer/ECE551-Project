module TourLogic(
  input clk, rst_n, go,
  input [2:0] x_start, y_start,
  input [4:0] indx,
  output done,
  output [7:0] move
);

task x_offset(
  input [7:0] movenum,
  output signed [2:0] offset
);
case (movenum)
  8'h01:
    offset = -1;
  8'h02:
    offset =  1;
  8'h04:
    offset = -2;
  8'h08:
    offset = -2;
  8'h10:
    offset = -1;
  8'h20:
    offset =  1;
  8'h40:
    offset =  2;
  8'h80:
    offset =  2;
endcase

endtask

task y_offset(
  input [7:0] movenum,
  output signed [2:0] offset
);
case (movenum)
  8'h01:
    offset =  2;
  8'h02:
    offset =  2;
  8'h04:
    offset =  1;
  8'h08:
    offset = -1;
  8'h10:
    offset = -2;
  8'h20:
    offset = -2;
  8'h40:
    offset =  1;
  8'h80:
    offset = -1;
endcase

endtask

logic board [4:0][4:0];
logic nxt_board [4:0][4:0];
genvar i;
genvar j;
generate for (i = 0; i < 5; i = i + 1) begin
  for (j = 0; j < 5; j = j + 1) begin
    always_ff @(posedge clk, negedge rst_n)
      if (!rst_n)
        board[i][j] <= 1'b0;
      else
        board[i][j] <= nxt_board[i][j];
  end
end
endgenerate

typedef enum logic [2:0] {IDLE, INIT, POSS, MOVE, BACK} tourlogic_state_t;
tourlogic_state_t state, nxt_state;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    state <= IDLE;
  else
    state <= nxt_state;

always_comb begin

case(state)
  IDLE:;
  INIT:;
  POSS:;
  MOVE:;
  BACK:;
  default:;
endcase

end

endmodule

