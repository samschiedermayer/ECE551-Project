module TourLogic(
  input clk, rst_n, go,
  input [2:0] x_start, y_start,
  input [4:0] indx,
  output reg done,
  output reg [2:0] move
);


// counter for move number
logic [1:0] cnt_op;
logic [4:0] nxt_cnt;
reg [4:0] cnt;

always_comb begin
  case (cnt_op)
    2'b00: nxt_cnt = cnt;
    2'b01: nxt_cnt = 5'h00;
    2'b10: nxt_cnt = cnt + 1;
    2'b11: nxt_cnt = cnt - 1;
  endcase
end

always_ff @(posedge clk)
  cnt <= nxt_cnt;


// board registers
logic board_set;
logic board_en[4:0][4:0];
reg board[4:0][4:0]; 
always_ff @(posedge clk)
  for (int i = 0; i < 5; i++)
    for (int j = 0; j < 5; j++)
      board[j][i] <= board_en[j][i] ? board_set : board[j][i];


// moves registers
logic move_op;
logic [2:0] nxt_move;
reg [2:0] moves [23:0];
logic move_en [23:0];

assign nxt_move = move_op ? (moves[cnt] + 1) : 3'h0;

always_ff @(posedge clk)
  for (int i = 0; i < 24; i++)
    moves[i] <= move_en[i] ? nxt_move : moves[i];


// x and y positions
logic [1:0] xy_op;
logic [3:0] nxt_x, nxt_y;
logic signed [2:0] dx, dy;
logic [3:0] x_plus, y_plus;
reg signed [3:0] x, y;

assign x_plus = x + dx;
assign y_plus = y + dy;

always_comb begin
  case (moves[cnt])
    3'b000: begin
      dx = 3'b111;
      dy = 3'b010;
    end
    3'b001: begin
      dx = 3'b001;
      dy = 3'b010;
    end
    3'b010: begin
      dx = 3'b110;
      dy = 3'b001;
    end
    3'b011: begin
      dx = 3'b110;
      dy = 3'b111;
    end
    3'b100: begin
      dx = 3'b111;
      dy = 3'b110;
    end
    3'b101: begin
      dx = 3'b001;
      dy = 3'b110;
    end
    3'b110: begin
      dx = 3'b010;
      dy = 3'b111;
    end
    3'b111: begin
      dx = 3'b010;
      dy = 3'b001;
    end
  endcase

  case (xy_op)
    2'b00: begin
      nxt_x = x;
      nxt_y = y;
    end
    2'b01: begin
      nxt_x = x_start;
      nxt_y = y_start;
    end
    2'b10: begin
      nxt_x = x_plus;
      nxt_y = y_plus;
    end
    2'b11: begin
      nxt_x = x - dx;
      nxt_y = y - dy;
    end
  endcase
end

always_ff @(posedge clk) begin
  x <= nxt_x;
  y <= nxt_y;
end


// flop for done signal and logic for move output
logic clr_done, set_done;

assign move = moves[indx];

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    done <= 1'b0;
  else
    done <= (~clr_done) & (set_done | done);


// signals for state machine
logic in_bounds;
logic not_occupied;
logic finished;
logic last;
logic backtrack;
logic valid;

assign in_bounds = (x_plus<5)&(~x_plus[3])&(y_plus<5)&(~y_plus[3]);

assign not_occupied = (in_bounds) ? ~(board[y_plus][x_plus]) : 1'b1;

assign finished = (cnt == 5'h18);

assign last = &(moves[cnt]);

assign backtrack = (last)&((~in_bounds)|(~not_occupied));

assign valid = in_bounds&not_occupied;


// state machine
typedef enum logic [2:0] { IDLE, INIT, SOLV, BAK1, BAK2, BAK3, VALD, FINI } tl_state_t;

tl_state_t state, nxt_state;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    state <= IDLE;
  else
    state <= nxt_state;

always_comb begin
  nxt_state = state;

  cnt_op    = 2'b00;
  xy_op     = 2'b00;
  move_op   = 1'b0;
  board_set = 1'b0;

  clr_done = 1'b0;
  set_done = 1'b0;

  for (int i = 0; i < 24; i++)
    move_en[i] = 1'b0;

  for (int i = 0; i < 5; i++)
    for (int j = 0; j < 5; j++)
      board_en[j][i] = 1'b0;

  case (state)
    IDLE: if (go) begin
      cnt_op = 2'b01;
      xy_op  = 2'b01;

      for (int i = 0; i < 24; i++)
        move_en[i] = 1'b1;

      for (int i = 0; i < 5; i++)
        for (int j = 0; j < 5; j++)
          board_en[j][i] = 1'b1;

      nxt_state = INIT;
    end

    INIT: begin
      board_en[y][x] = 1'b1;
      board_set = 1'b1;

      nxt_state = SOLV;
    end

    SOLV: if (finished) begin // solution has been found
      set_done = 1'b1;

      nxt_state = FINI;
    end else if (backtrack) begin // move 7 invalid, so need to backtrack
      board_en[y][x] = 1'b1;
      move_en[cnt]   = 1'b1;
      cnt_op         = 2'b11;

      nxt_state = BAK1;
    end else if (valid) begin // valid move found, continue to next move
      cnt_op = 2'b10;
      xy_op  = 2'b10;

      nxt_state = VALD;
    end else begin // try next move
      move_op = 1'b1;
      move_en[cnt] = 1'b1;
    end

    BAK1: begin
      xy_op = 3;

      nxt_state = BAK2;
    end

    BAK2: if (last) begin
      board_en[y][x] = 1'b1;
      move_en[cnt]   = 1'b1;
      cnt_op         = 2'b11;

      nxt_state = BAK3;
    end else begin
      move_en[cnt] = 1'b1;
      move_op      = 1'b1;

      nxt_state = SOLV;
    end

    BAK3: begin
      xy_op = 3;

      nxt_state = BAK2;
    end

    VALD: begin
      board_en[y][x] = 1'b1;
      board_set      = 1'b1;

      nxt_state = SOLV;
    end

    default: begin //FINI state
      clr_done = 1'b1;

      nxt_state = IDLE;
    end

  endcase
end

endmodule








