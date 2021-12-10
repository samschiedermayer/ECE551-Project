`timescale 1ns/1ps
module PID_tb;

logic clk, rst_n, moving, err_vld;

logic [11:0] error;
logic  [9:0] frwrd;
logic [10:0] lft_spd, rght_spd, exp_lft, exp_rght;

PID iDut(.clk(clk),.rst_n(rst_n),.moving(moving),.err_vld(err_vld),
	.error(error),.frwrd(frwrd),.lft_spd(lft_spd),.rght_spd(rght_spd));

reg [24:0] stim[0:1999];
reg [21:0] resp[0:1999];

logic tb_err;
initial begin
  tb_err = 0;

  // initialize values
  clk = 0;
  rst_n = 1;
  moving = 0;
  err_vld = 0;
  error = 0;
  frwrd = 0;

  // read in vectors
  $readmemh("PID_stim.hex",stim);
  $readmemh("PID_resp.hex",resp);

  // loop through the vectors and check input vs output
  for (int i = 0; i < 2000; i++) begin
    @(negedge clk);
    rst_n   = stim[i][24];
    moving  = stim[i][23];
    err_vld = stim[i][22];
    error   = stim[i][21:10];
    frwrd   = stim[i][ 9: 0];

    exp_lft  = resp[i][21:11];
    exp_rght = resp[i][10: 0];
    @(posedge clk);
    #4;
    if (lft_spd !== exp_lft) begin
      $display("Error, lft_spd does not match for input %i.  Expected: %x, Actual: %x",i,exp_lft,lft_spd);
      tb_err = 1;
    end
    if (rght_spd !== exp_rght) begin
      $display("Error, rght_spd does not match for input %i. Expected: %x, Actual: %x",i,exp_rght,rght_spd);
      tb_err = 1;
    end
  end

  if (0 === tb_err)
    $display("Yahoo! Tests passed :)");
  $stop();
end

always #5 clk = ~clk;

endmodule

