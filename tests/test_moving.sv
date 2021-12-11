module test_moving();

  // import tasks
  import tb_tasks::*;
  
  /////////////////////////////
  // Stimulus of type reg //
  /////////////////////////
  reg clk, RST_n;
  reg [15:0] cmd;
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

  task automatic checkPositiveAck(input int timeout);

    wait_for_sig(clk, resp_rdy, timeout, 1'b1, "resp_rdy was not asserted after sending command", tb_err, cycles);

  endtask : checkPositiveAck
  
  task automatic sendCommand(input logic [15:0] cmd_to_send, input logic wait_for_cal, input integer timeout);

    @(negedge clk);
    cmd = cmd_to_send;
    send_cmd = 1;
    @(negedge clk);
    send_cmd = 0;

    wait_for_sig(clk, cmd_sent, 200000, 1'b1, "cmd_sent was not asserted after sending command", tb_err, cycles);

    // wait for cal_done to be asserted
    if (wait_for_cal)
      wait_for_sig(clk, iDUT.cal_done, 200000, 1'b1, "cal_done was not asserted after sending command", tb_err, cycles);

    // wait for acknowledgement to be received
    checkPositiveAck(timeout);

  endtask : sendCommand
   
  initial begin
    tb_err = 0;

    initialize();

    // send the calibrate command to the DUT
    $display("Sending calibrate command to DUT...");
    sendCommand(16'h0000,1'b1,350000);

    ///////////////////////////////////////////////////////////////////
    // Moving 1 square east					    //
    /////////////////////////////////////////////////////////////////
    $display("Moving 1 square east");
    sendCommand(16'h2bf1,1'b0,4000000);

    if (!((iDUT.iCMD.heading > -1100) && (iDUT.iCMD.heading < -1000))) begin
      $display("heading is not close to -1024");
      tb_err = 1; 
    end
   
    if (!((iPHYS.xx < 15000) && (iPHYS.xx > 10000))) begin
      $display("xx is not close to 12500");
      tb_err = 1; 
    end

    if (!((iPHYS.yy > 10200) && (iPHYS.yy < 10400))) begin
      $display("yy is not close to 10300");
      tb_err = 1; 
    end 

    ///////////////////////////////////////////////////////////////////
    // Moving 1 square north					    //
    /////////////////////////////////////////////////////////////////
    $display("moving 1 square north");
    sendCommand(16'h2001,1'b0,4000000);

    if (!((iDUT.iCMD.heading > -100) && (iDUT.iCMD.heading < 100))) begin
      $display("heading is not close to 0");
      tb_err = 1; 
    end
   
    if (!((iPHYS.xx > 13500) && (iPHYS.xx < 14500))) begin
      $display("xx is not close to 14000");
      tb_err = 1; 
    end

    if (!((iPHYS.yy > 13500) && (iPHYS.yy < 14500))) begin
      $display("yy is not close to 14000");
      tb_err = 1; 
    end 

    ///////////////////////////////////////////////////////////////////
    // Moving 1 square west					    //
    /////////////////////////////////////////////////////////////////
    $display("moving 1 square west");
    sendCommand(16'h23f1,1'b0,4000000);

    if (!((iDUT.iCMD.heading > 1000) && (iDUT.iCMD.heading < 1100))) begin
      $display("heading is not close to 1050");
      tb_err = 1; 
    end
   
    if (!((iPHYS.xx < 10700) && (iPHYS.xx > 10000))) begin
      $display("xx is not close to 10300");
      tb_err = 1; 
    end

    if (!((iPHYS.yy > 13500) && (iPHYS.yy < 14500))) begin
      $display("yy is not close to 14000");
      tb_err = 1; 
    end 

    ///////////////////////////////////////////////////////////////////
    // Moving 1 square south     				    //
    /////////////////////////////////////////////////////////////////
    $display("moving 1 square south");
    sendCommand(16'h27f1,1'b0,4000000);

    if (!(iDUT.iCMD.heading > 12'h7ee)) begin
      $display("heading is not close to 7ff");
      tb_err = 1; 
    end
   
    if (!((iPHYS.xx > 10300) && (iPHYS.xx < 10400))) begin
      $display("xx is not close to 10350");
      tb_err = 1; 
    end

    if (!((iPHYS.yy < 10700) && (iPHYS.yy > 10000))) begin
      $display("yy is not close to 10400");
      tb_err = 1; 
    end 



    //$monitor("current_heading: %x, x position: %x, y position: %x",iDUT.heading,iPHYS.xx,iPHYS.yy);
    // send the north command to the DUT
    //$display("Sending north command");
    //sendCommand(16'h2001,1'b0,2000000);

    // send the west  command to the DUT
    //$display("Sending west command");
    //sendCommand(16'h23f1,1'b0,4000000);

    // send the east  command to the DUT
    //$display("Sending east command");
    //sendCommand(16'h2bf1,1'b0,6000000);

    // send the south command to the DUT
    //$display("Sending south command");
    //sendCommand(16'h27f1,1'b0,4000000);

    if (tb_err === 0)
      $display("Yahoo! All tests passed :)");
  
  	$stop();
  end
  
  always
    #5 clk = ~clk;

  //always
  //  force iPHYS.iNEMO.NEMO_setup = 1'b0;
  
endmodule
