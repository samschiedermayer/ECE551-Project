module TourCmd_tb();

///////////////////////////////////////////////////////////////
// Declare signals                                          //
/////////////////////////////////////////////////////////////
logic clk,rst_n;			// 50MHz clock and asynch active low reset
logic start_tour;			// from done signal from TourLogic
reg [7:0] move;			// encoded 1-hot move to perform
reg [4:0] mv_indx;	// "address" to access next move
logic [15:0] cmd_UART;	// cmd from UART_wrapper
logic cmd_rdy_UART;		// cmd_rdy from UART_wrapper
logic [15:0] cmd;		// multiplexed cmd to cmd_proc
logic cmd_rdy;			// cmd_rdy signal to cmd_proc
logic clr_cmd_rdy;		// from cmd_proc (goes to UART_wrapper too)
logic send_resp;			// lets us know cmd_proc is done with command
logic [7:0] resp;

reg [7:0] stim[0:23]; // 15-bit wide 24 entry ROM
logic [31:0] formed_cmd[0:23]; // 32-bit wide 24 entry ROM


///////////////////////////////////////////////////////////////
// Instantiate the DUT                                      //
/////////////////////////////////////////////////////////////
TourCmd iDUT(.clk(clk),.rst_n(rst_n),.start_tour(start_tour),.move(move),.mv_indx(mv_indx),
.cmd_UART(cmd_UART),.cmd(cmd),.cmd_rdy_UART(cmd_rdy_UART),.cmd_rdy(cmd_rdy),
			   .clr_cmd_rdy(clr_cmd_rdy),.send_resp(send_resp),.resp(resp));

///////////////////////////////////////////////////////////
// Task for waiting for signals or timing out the test  //
/////////////////////////////////////////////////////////
task automatic wait_for_sig(ref sig, input int clks_to_wait, input int pos);
  fork
    begin : timeout
      repeat(clks_to_wait) @(posedge clk);
      $display("TEST FAILED");
      $display("ERROR: timed out waiting for signal, %d clock cycles", clks_to_wait);
      $stop();
    end
    begin
      if(pos === 1) begin
        $display("Waiting for posedge");
        @(posedge sig);
      end
      else begin
        $display("Waiting for negedge");
        @(negedge sig);
      end
      disable timeout;
    end
  join
endtask

///////////////////////////////////////////////////////////////////
// Task for testing the cmd responses based on different moves  //
/////////////////////////////////////////////////////////////////
task automatic test_moves(ref [15:0] cmd, input [7:0] stim_move, input [15:0] formed_cmd1, input [15:0] formed_cmd2, input int i);
    $display("Executing Test %0d", i+1);

    $displayh("stim_move: %p", stim_move);
    $displayh("formed_cmd1: %p", formed_cmd1);
    $displayh("formed_cmd2: %p", formed_cmd2);

    // start_tour = 1'b1;
    move = stim_move;
    clr_cmd_rdy = 1'b1;

    $display("Waiting for cmd_rdy done");
    wait_for_sig(cmd_rdy, 100000, 1);

    @(posedge clk);
    // start_tour = 1'b0;
    clr_cmd_rdy = 1'b1;
    @(posedge clk);

    clr_cmd_rdy = 1'b1;
    @(posedge clk);
    clr_cmd_rdy = 1'b0;

    send_resp = 1'b1;
    @(posedge clk);
    send_resp = 1'b0;
    if(cmd !== formed_cmd1) begin
        $display("Test %0d FAILED", i+1);
        $displayh("cmd was: %p", cmd);
        $displayh("cmd should be: %p", formed_cmd1);
        $stop();
    end

    
    $display("Waiting for cmd_rdy done");
    wait_for_sig(cmd_rdy, 100000, 1);
     clr_cmd_rdy = 1'b1;
    @(posedge clk);
    clr_cmd_rdy = 1'b0;
    send_resp = 1'b1;
    @(posedge clk);
    send_resp = 1'b0;

    if(cmd !== formed_cmd2) begin
        $display("Test %0d FAILED", i+1);
        $displayh("cmd was: %p", cmd);
        $displayh("cmd should be: %p", formed_cmd2);
        $stop();
    end

    $display("Test %0d PASSED", i+1);
endtask

///////////////////////////////////////////////////////////////
// Testing Logic                                            //
/////////////////////////////////////////////////////////////
initial begin
  
    $readmemh("TourCmd_stim.hex", stim);
    $readmemh("TourCmd_resp.hex", formed_cmd);

    clk = 0;
    rst_n = 0;
    cmd_rdy_UART = 1'b0;
    cmd_UART = 16'h0000;
    @(posedge clk);
    @(negedge clk);
    start_tour = 1'b1;
    rst_n = 1;
    @(posedge clk);
    start_tour = 1'b0;

    foreach (stim[i])begin
      test_moves(cmd, stim[i], formed_cmd[i][31:16], formed_cmd[i][15:0], i);
    end

    $display("Yahoo, all tests passed!");
    $stop();
end

always 
    #10 clk <= ~clk;

endmodule