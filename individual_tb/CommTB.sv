module CommTB();

logic clk, rst_n;		// clock and active low reset

// Remote Comm Inputs
logic snd_cmd;			// indicates to tranmit 24-bit command (cmd)
logic [15:0] REMOTE_cmd;		// 16-bit command

// Remote Comm Outputs
reg cmd_snt;		// indicates transmission of command complete
logic resp_rdy;		// indicates 8-bit response has been received
logic [7:0] REMOTE_resp;		// 8-bit response from DUT

// UART_wrapper inputs
logic clr_cmd_rdy;
logic trmt;
logic [7:0] UART_resp;

// UART_wraper outputs
logic cmd_rdy;
logic [15:0] UART_cmd;
logic tx_done;

// Common Signals
logic TX, RX;

logic UART_to_REMOTE;
logic REMOTE_to_UART;
logic WR_resp, RC_resp;

////////////////////////////////////////////////////////////////////
// Instantiate Remote Comm and UART_wrapper hooking up RX AND TX //
//////////////////////////////////////////////////////////////////
RemoteComm iDUT_RM(.clk(clk), .rst_n(rst_n), .RX(UART_to_REMOTE), .TX(REMOTE_to_UART), .cmd(REMOTE_cmd), .snd_cmd(snd_cmd), .cmd_snt(cmd_snt), .resp_rdy(resp_rdy), .resp(RC_resp));
UART_wrapper  iDUT_W(.clk(clk), .rst_n(rst_n), .clr_cmd_rdy(clr_cmd_rdy), .trmt(cmd_snt), .resp(WR_resp), .RX(REMOTE_to_UART), .TX(UART_to_REMOTE), .cmd_rdy(cmd_rdy), .cmd(UART_cmd), .tx_done(tx_done));

///////////////////////////////////////////////////////////////
// Task for waiting for signals or timeing out the test     //
/////////////////////////////////////////////////////////////
task automatic wait_for_sig(ref sig, input int clks_to_wait);
  fork
    begin : timeout
      repeat(clks_to_wait) @(posedge clk);
      $display("ERROR: timed out waiting for signal, %d clock cycles", clks_to_wait);
      $stop();
    end
    begin
      @(posedge sig);
      disable timeout;
    end
  join
endtask

///////////////////////////////////////////////////////////////
// Testing Logic                                            //
/////////////////////////////////////////////////////////////
initial begin
  ///////////////////////////////////////////////////////////////
  // Default values and DUT reset                             //
  /////////////////////////////////////////////////////////////
    clk = 0;
    rst_n = 0;
    clr_cmd_rdy = 0;

    // reset 
    @(posedge clk);
    @(negedge clk);
    rst_n = 1;
    // clr_cmd_rdy = 0;

  ///////////////////////////////////////////////////////////////
  // Test 1                                                   //
  /////////////////////////////////////////////////////////////
    REMOTE_cmd = 16'h0000;
    @(posedge clk);
    snd_cmd = 1;
    @(posedge clk);
    snd_cmd = 0;

    $display("Executing Test 1");
    $display("Watiting for cmd_rdy");
    wait_for_sig(cmd_rdy, 70000);
    $display("Waiting for cmd_snt");
    wait_for_sig(cmd_snt, 70000);

    if(REMOTE_cmd !== UART_cmd)begin
      $display("Test 1 Failed" );
      $display("CMD Sent: %0h", REMOTE_cmd);
      $display("CMD Recieved: %0h", UART_cmd);
      $stop();
    end

  ///////////////////////////////////////////////////////////////
  // Test 2                                                   //
  /////////////////////////////////////////////////////////////
    @(posedge resp_rdy)

    REMOTE_cmd = 16'hFFFF;
    @(posedge clk);
    snd_cmd = 1;
    @(posedge clk);
    snd_cmd = 0;

    $display("Executing Test 2");
    $display("Watiting for cmd_rdy");
    wait_for_sig(cmd_rdy, 70000);
    $display("Waiting for cmd_snt");
    wait_for_sig(cmd_snt, 70000);

    if(REMOTE_cmd !== UART_cmd)begin
      $display("Test 2 Failed" );
      $display("CMD Sent: %0h", REMOTE_cmd);
      $display("CMD Recieved: %0h", UART_cmd);
      $stop();
    end

  ///////////////////////////////////////////////////////////////
  // Test 3                                                   //
  /////////////////////////////////////////////////////////////
    @(posedge resp_rdy)

    REMOTE_cmd = -16'hFFFF;
    @(posedge clk);
    snd_cmd = 1;
    @(posedge clk);
    snd_cmd = 0;

    $display("Executing Test 3");
    $display("Watiting for cmd_rdy");
    wait_for_sig(cmd_rdy, 70000);
    $display("Waiting for cmd_snt");
    wait_for_sig(cmd_snt, 70000);

    if(REMOTE_cmd !== UART_cmd)begin
      $display("Test 3 Failed" );
      $display("CMD Sent: %0h", REMOTE_cmd);
      $display("CMD Recieved: %0h", UART_cmd);
      $stop();
    end

  ///////////////////////////////////////////////////////////////
  // Test 4                                                   //
  /////////////////////////////////////////////////////////////
    @(posedge resp_rdy)

    @(posedge clk);
    clr_cmd_rdy = 1;
    @(posedge clk);
    clr_cmd_rdy = 0;

    repeat (2) @(posedge clk);

    $display("Executing Test 4");

    if(cmd_rdy !== 1'b0)begin
      $display("Test 4 Failed" );
      $display("cmd_rdy: %0h", cmd_rdy);
      $stop();
    end

  ///////////////////////////////////////////////////////////////
  // Test 5                                                   //
  /////////////////////////////////////////////////////////////
    @(posedge resp_rdy)

    REMOTE_cmd = 16'h0000;
    @(posedge clk);
    snd_cmd = 1;
    @(posedge clk);
    snd_cmd = 0;

    $display("Executing Test 5");
    $display("Watiting for cmd_rdy");
    wait_for_sig(cmd_rdy, 70000);
    $display("Waiting for cmd_snt");
    wait_for_sig(cmd_snt, 70000);

    if(REMOTE_cmd !== UART_cmd)begin
      $display("Test 5 Failed" );
      $display("CMD Sent: %0h", REMOTE_cmd);
      $display("CMD Recieved: %0h", UART_cmd);
      $stop();
    end

  ///////////////////////////////////////////////////////////////
  // Test 6                                                   //
  /////////////////////////////////////////////////////////////
    @(posedge resp_rdy)

    REMOTE_cmd = 16'hBBBB;
    @(posedge clk);
    snd_cmd = 1;
    @(posedge clk);
    snd_cmd = 0;

    $display("Executing Test 5");
    $display("Watiting for cmd_rdy");
    wait_for_sig(cmd_rdy, 70000);
    $display("Waiting for cmd_snt");
    wait_for_sig(cmd_snt, 70000);

    if(REMOTE_cmd !== UART_cmd)begin
      $display("Test 6 Failed" );
      $display("CMD Sent: %0h", REMOTE_cmd);
      $display("CMD Recieved: %0h", UART_cmd);
      $stop();
    end

  ///////////////////////////////////////////////////////////////
  // Test 7                                                   //
  /////////////////////////////////////////////////////////////
    @(posedge resp_rdy)

    REMOTE_cmd = -16'h195F;
    @(posedge clk);
    snd_cmd = 1;
    @(posedge clk);
    snd_cmd = 0;

    $display("Executing Test 5");
    $display("Watiting for cmd_rdy");
    wait_for_sig(cmd_rdy, 70000);
    $display("Waiting for cmd_snt");
    wait_for_sig(cmd_snt, 70000);

    if(REMOTE_cmd !== UART_cmd)begin
      $display("Test 6 Failed" );
      $display("CMD Sent: %0h", REMOTE_cmd);
      $display("CMD Recieved: %0h", UART_cmd);
      $stop();
    end

    $display("Yahoo, all tests passed!");
    $stop();
end

always
  #10 clk <= ~clk;
endmodule