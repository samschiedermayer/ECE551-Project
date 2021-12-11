module test_tour();

  // import tasks
  import tb_tasks::*;
  
  /////////////////////////////
  // Stimulus of type reg //
  /////////////////////////
  reg clk, RST_n; reg [15:0] cmd;
  reg send_cmd;
  
  ///////////////////////////////////
  // Declare any internal signals //
  /////////////////////////////////
  wire SS_n,SCLK,MOSI,MISO,INT;
  logic lftPWM1,lftPWM2,rghtPWM1,rghtPWM2;
  wire TX_RX, RX_TX;
  logic cmd_sent;
  logic resp_rdy;
  logic [7:0] resp;
  wire IR_en;
  wire lftIR_n,rghtIR_n,cntrIR_n;
  
  //////////////////////
  // Instantiate DUT //
  ////////////////////
  KnightsTour iDUT(.clk(clk), .RST_n(RST_n), .SS_n(SS_n), .SCLK(SCLK),
                   .MOSI(MOSI), .MISO(MISO), .INT(INT), .lftPWM1(lftPWM1),
				   .lftPWM2(lftPWM2), .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2),
				   .RX(TX_RX), .TX(RX_TX), .piezo(piezo), .piezo_n(piezo_n),
				   .IR_en(IR_en), .lftIR_n(lftIR_n), .rghtIR_n(rghtIR_n),
				   .cntrIR_n(cntrIR_n));
				  
  /////////////////////////////////////////////////////
  // Instantiate RemoteComm to send commands to DUT //
  ///////////////////////////////////////////////////
  RemoteComm iRMT(.clk(clk), .rst_n(RST_n), .RX(RX_TX), .TX(TX_RX), .cmd(cmd),
             .snd_cmd(send_cmd), .cmd_snt(cmd_sent), .resp_rdy(resp_rdy), .resp(resp));
				   
  //////////////////////////////////////////////////////
  // Instantiate model of Knight Physics (and board) //
  ////////////////////////////////////////////////////
  KnightPhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),
                      .MOSI(MOSI),.INT(INT),.lftPWM1(lftPWM1),.lftPWM2(lftPWM2),
					  .rghtPWM1(rghtPWM1),.rghtPWM2(rghtPWM2),.IR_en(IR_en),
					  .lftIR_n(lftIR_n),.rghtIR_n(rghtIR_n),.cntrIR_n(cntrIR_n)); 

  // flag for whether we have encountered an error in the test	
  logic tb_err;
  // counter for how many cycles waiting for edges takes, for debug
  int cycles;

  // tourlogic specific tasks
  task automatic initialize ();

    clk = 0;
    send_cmd = 0;
    cmd = 16'h0000;

    RST_n = 1'b0;
    @(negedge clk);
    RST_n = 1'b1;
    @(negedge clk);

    repeat (20) @(posedge clk);

    // wait for NEMO setup
    wait_for_sig(clk, iPHYS.iNEMO.NEMO_setup, 100000, 1'b1, "NEMO setup did not assert upon reset", tb_err, cycles);

    // wait for each pwm to rise and fall once
    wait_for_sig(clk, lftPWM1, 3000, 1'b1, "lftPWM1 did not rise after reset", tb_err, cycles);
    wait_for_sig(clk, lftPWM1, 3000, 1'b0, "lftPWM1 did not fall after reset", tb_err, cycles);

    wait_for_sig(clk, lftPWM2, 3000, 1'b1, "lftPWM2 did not rise after reset", tb_err, cycles);
    wait_for_sig(clk, lftPWM2, 3000, 1'b0, "lftPWM2 did not fall after reset", tb_err, cycles);

    wait_for_sig(clk, rghtPWM1, 3000, 1'b1, "rghtPWM1 did not rise after reset", tb_err, cycles);
    wait_for_sig(clk, rghtPWM1, 3000, 1'b0, "rghtPWM1 did not fall after reset", tb_err, cycles);

    wait_for_sig(clk, rghtPWM2, 3000, 1'b1, "rghtPWM2 did not rise after reset", tb_err, cycles);
    wait_for_sig(clk, rghtPWM2, 3000, 1'b0, "rghtPWM2 did not fall after reset", tb_err, cycles);
    
  endtask : initialize

  task automatic checkPositiveAck(input int timeout, input logic cal);

    wait_for_sig(clk, resp_rdy, timeout, 1'b1, "resp_rdy was not asserted after sending command", tb_err, cycles);

    if (cal)
      err_on_cond_false(resp===8'hA5,tb_err,"response was not 0xA5 after cal");

  endtask : checkPositiveAck
  
  task automatic sendCommand(input logic [15:0] cmd_to_send, input logic wait_for_cal, wait_for_ack, input integer timeout);

    @(negedge clk);
    cmd = cmd_to_send;
    send_cmd = 1;
    @(negedge clk);
    send_cmd = 0;

    // wait for the cmd_sent signal after sending the command
    if (wait_for_ack)
      wait_for_sig(clk, cmd_sent, 200000, 1'b1, "cmd_sent was not asserted after sending command", tb_err, cycles);

    // wait for cal_done to be asserted
    if (wait_for_cal)
      wait_for_sig(clk, iDUT.cal_done, 200000, 1'b1, "cal_done was not asserted after sending command", tb_err, cycles);

    // wait for acknowledgement to be received
    if (wait_for_ack)
      checkPositiveAck(timeout,wait_for_cal);

  endtask : sendCommand
  
  task automatic moveWestOneSquare ();
    // Add code
  endtask : moveWestOneSquare


  logic sample;   
  initial begin
    tb_err = 0;
    sample = 0;

    // initialize the DUT
    $display("Initializing the DUT...");
    initialize();


    // CALIBRATE //
    $display("Sending calibrate command to DUT...");
    sendCommand(16'h0000,1'b1,1'b1,350000);


    // BEGIN TOUR //
    $display("Sending tour(2,2) command to DUT...");
    sendCommand(16'h4022,1'b0,1'b0,1000000);

    wait_for_sig(clk, iDUT.tour_go, 8000000, 1'b1, "tour_go was not asserted after sending a tour command", tb_err, cycles);
    wait_for_sig(clk, iDUT.start_tour, 10000000, 1'b1, "start_tour was not asserted after tour_go was asserted", tb_err, cycles);


    // MOVE 1 //
    $display("Validating the first move of the tour...");

    // ensure that the command is sent for the first move of the first tour
    wait_for_sig(clk, iDUT.cmd_rdy,2000000, 1'b1, "first move of the tour did not start", tb_err, cycles);

    // ensure that the first move is the correct move number
    repeat (2) @(posedge clk);
    err_on_cond_false(5'h00===iDUT.mv_indx,tb_err,"move index was not 0 at the start of the tour");
    err_on_cond_false(3'h0===iDUT.move,tb_err,"first move was not 0 at the start of the tour");
    err_on_cond_false(16'h2002===iDUT.cmd,tb_err,"first half of the first move is not 2 north as expected");

    wait_for_sig(clk, iDUT.cmd_rdy,12000000, 1'b1, "first half of the first move of the tour did not finish", tb_err, cycles);

    // validate the first move of the tour
    repeat (2) @(posedge clk);
    err_on_cond_false(16'h33f1===iDUT.cmd,tb_err,"second half of the first move is not 1 west as expected");

    wait_for_sig(clk, iDUT.cmd_rdy, 12000000, 1'b1, "first move of the tour did not finish", tb_err, cycles);


    // MOVE 2 //
    $display("Validating the second move of the tour...");

    // check the move that is active, and whether the command for the first half is correct
    repeat (2) @(posedge clk);
    err_on_cond_false(5'h01===iDUT.mv_indx,tb_err,"move index was not 1 after first move of tour");
    err_on_cond_false(3'h4===iDUT.move,tb_err,"second move was not 4");
    err_on_cond_false(16'h27f2===iDUT.cmd,tb_err,"first half of the second move is not 2 south as expected");

    // make sure the first half of the first move finishes
    wait_for_sig(clk, iDUT.cmd_rdy, 12000000, 1'b1, "first half of second move of the tour did not finish", tb_err, cycles);

    // make sure that the second half of the second move has the correct command
    repeat (2) @(posedge clk);
    err_on_cond_false(16'h33f1===iDUT.cmd,tb_err,"second half of the second move is not 1 west as expected");

    // ensure that the second half of the second move finishes
    wait_for_sig(clk, iDUT.cmd_rdy, 12000000, 1'b1, "second half of second move of the tour did not finish", tb_err, cycles);

    // ensure that the third move is loaded correctly after the second move finishes
    err_on_cond_false(5'h02===iDUT.mv_indx,tb_err,"move index was not 2 after second move of tour");
    err_on_cond_false(3'h5===iDUT.move,tb_err,"first move was not 0 at the start of the tour");


    // finish the test
    if (tb_err === 0)
      $display("Yahoo! All tests passed :)");
  
  	$stop();
  end
  
  always
    #5 clk = ~clk;

  //always
  //  force iPHYS.iNEMO.NEMO_setup = 1'b0;
  
endmodule
