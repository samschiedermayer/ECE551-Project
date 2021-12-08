module TourLogic(
  input clk, rst_n, go,
  input [2:0] x_start, y_start,
  input [4:0] indx,
  output done,
  output [7:0] move
);
genvar i;
genvar j;

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

logic rst_move_num;
logic [4:0] move_num, nxt_move_num;
always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    move_num <= 5'h00;
  else
    move_num <= (rst_move_num) ? 5'h00 : nxt_move_num;

logic rst_moves;

logic [7:0] moves [24:0];
logic [7:0] nxt_moves [24:0];
generate for (i = 0; i < 25; i = i + 1) begin
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      moves[i] <= 8'h00;
    else
      moves[i] <= (rst_moves) ? 8'h00 : nxt_moves[i];
end
endgenerate

logic [7:0] poss_moves [24:0];
logic [7:0] nxt_poss_moves [24:0];
generate for (i = 0; i < 25; i = i + 1) begin
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      poss_moves[i] <= 8'h00;
    else
      poss_moves[i] <= (rst_moves) ? 8'h00 : poss_moves[i];
end
endgenerate

logic rst_board;
logic board [4:0][4:0];
logic nxt_board [4:0][4:0];
generate for (i = 0; i < 5; i = i + 1) begin
  for (j = 0; j < 5; j = j + 1) begin
    always_ff @(posedge clk, negedge rst_n)
      if (!rst_n)
        board[i][j] <= 1'b0;
      else
        board[i][j] <= (rst_board) ? 1'b0 : nxt_board[i][j];
  end
end
endgenerate

logic increment;
logic signed [2:0] dx, dy;
logic [2:0] x, nxt_x, y, nxt_y;
always_ff @(posedge clk) begin
  x <= (increment) ? nxt_x + dx : nxt_x;
  y <= (increment) ? nxt_y + dy : nxt_y;
end

logic inc_try;
logic [7:0] try, nxt_try;
always_ff @(posedge clk)
  try <= (inc_try) ? {nxt_try[6:0],1'b0} : nxt_try;

typedef enum logic [2:0] {IDLE, INIT, POSS, MOVE, BACK} tourlogic_state_t;

tourlogic_state_t state, nxt_state;
always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    state <= IDLE;
  else
    state <= nxt_state;

always_comb begin
nxt_state = state;
nxt_board = board;
nxt_moves = moves;
nxt_poss_moves = poss_moves;
nxt_move_num = move_num;
nxt_x = x;
nxt_y = y;
nxt_try = try;

rst_board = 0;
rst_moves = 0;
rst_move_num = 0;
increment = 0;
inc_try = 0;

case(state)
  IDLE: if (go) begin
    rst_board = 1;
    rst_moves = 1;
    rst_move_num = 1;
    nxt_state = INIT;
  end
  INIT: begin
    nxt_board[x_start][y_start] = 1;
    nxt_x = x_start;
    nxt_y = y_start;
    nxt_state = POSS;
  end
  POSS: begin
    // calc_possible(x,y,poss_moves[move_num]);
    nxt_try = 8'h01;
    nxt_state = MOVE;
  end
  MOVE:;
  BACK:;
  default:;
endcase

end

endmodule

