module PID(
  input clk, rst_n, moving, err_vld,
  input  [11:0] error,
  input   [9:0] frwrd,
  output [10:0] lft_spd, rght_spd
);

logic [10:0] frwrd_zext;
logic [13:0] P_term, I_term_sext, D_term_sext;
logic [8:0] I_term;
logic [12:0] D_term; 

//saturation
logic signed [9:0] err_sat;
assign err_sat = 
    (error[11] && !(&error[10:9])) ? 10'h200 //negative saturate
  : (!error[11] && |error[10:9]) ? 10'h1FF //positive saturate
  :  error[9:0]; //no need to saturate

// D term calculation
localparam [5:0] D_COEFF = 6'h0B;
logic [9:0] cur_err, prev_err, D_diff;
logic signed [6:0] D_diff_sat;

always_ff @(negedge rst_n, posedge clk)
  if (!rst_n) begin
    cur_err  <= 10'b0;
    prev_err <= 10'b0;
  end else begin
    cur_err  <= (err_vld) ? err_sat : cur_err;
    prev_err <= (err_vld) ? cur_err : prev_err;
  end

assign D_diff = err_sat - prev_err;
assign D_diff_sat =
      (D_diff[9] && !(&D_diff[8:6])) ? 7'h40 //negative saturate
    : (!D_diff[9] && |D_diff[8:6])   ? 7'h3F //positive saturate
    :  D_diff[6:0]; //no need to saturate

assign D_term = D_diff_sat * $signed(D_COEFF);

// I term calculation
logic [14:0] nxt_integrator, cur_integrator, sum;
logic overflow;
always_ff @(posedge clk, negedge rst_n)
  if(!rst_n)
	cur_integrator <= 15'h0000;
  else
  	cur_integrator <= nxt_integrator;

assign sum = cur_integrator[14:0] + {{5{err_sat[9]}},err_sat[9:0]};
assign overflow = (cur_integrator[14] & err_sat[9] & ~sum[14])
                | (~cur_integrator[14] & ~err_sat[9] & sum[14]);
assign nxt_integrator = (moving) ? 
            ((err_vld & ~overflow) ? sum : cur_integrator)
            : 15'h0000;

assign I_term = cur_integrator[14:6];

// P TERM STUFF
localparam [4:0] P_COEFF = 5'h8;

// compute sums
logic [13:0] PID_sum;
logic [10:0] left_sum, right_sum;

// pipeline reg 1
always_ff @(posedge clk) begin
  frwrd_zext <= {1'b0,frwrd};
  P_term = err_sat * $signed(P_COEFF[4:0]);
  I_term_sext = {{5{I_term[8] }},I_term};
  D_term_sext = {{1{D_term[12]}},D_term};
end

assign PID_sum = I_term_sext + D_term_sext + P_term;

// Pipeline reg 2
always_ff @(posedge clk) begin
  left_sum <= (moving) ? (frwrd_zext + PID_sum[13:3]) : 11'h000;
  right_sum <= (moving) ? (frwrd_zext - PID_sum[13:3]) : 11'h000;
end

// saturate outputs
assign lft_spd  = (~PID_sum[13] &  left_sum[10]) ? 11'h3FF : left_sum;
assign rght_spd = ( PID_sum[13] & right_sum[10]) ? 11'h3FF : right_sum;

endmodule

