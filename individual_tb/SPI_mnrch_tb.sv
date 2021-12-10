module SPI_mnrch_tb();

///////////////////////////////////////////////////////////////
// Declare signals                                          //
/////////////////////////////////////////////////////////////
logic clk, rst_n;
logic MISO;
logic wrt;
logic [15:0] wt_data;
logic SS_n, SCLK, MOSI;
logic done;
logic [15:0] rd_data;
logic INT;

///////////////////////////////////////////////////////////////
// Instantiate the DUT and SPI_iNEMO1                       //
/////////////////////////////////////////////////////////////
SPI_mnrch iDUT(.clk(clk), .rst_n(rst_n), .MISO(MISO), .wrt(wrt), .wt_data(wt_data), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .done(done), .rd_data(rd_data));
SPI_iNEMO1 iNEMO(.SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), . MISO(MISO), .INT(INT));

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

///////////////////////////////////////////////////////////////
// Testing Logic                                            //
/////////////////////////////////////////////////////////////
initial begin
  ///////////////////////////////////////////////////////////////
  // Default values and DUT reset                             //
  /////////////////////////////////////////////////////////////
    clk = 0;
    rst_n = 0;
    @(posedge clk);
    @(negedge clk);
    rst_n = 1;

    ///////////////////////////////////////////////////////////////
    // Test 1: Reading from the WHO_AM_I register               //
    /////////////////////////////////////////////////////////////
    $display("Executing Test 1");
    wt_data = 16'h8Fxx;
    @(negedge clk);
    wrt = 1;
    @(posedge clk);
    wrt = 0;

    $display("Waiting for sig done");
    wait_for_sig(done, 100000, 1);
    if(rd_data !== 8'h6A) begin
        $display("Test 1 FAILED" );
        $display("WHO_AM_I register contained: %0h", rd_data);
        $display("WHO_AM_I register should contain: %0h", 16'hXX6A);
        $stop();
    end
    $display("Test 1 PASSED");

    ///////////////////////////////////////////////////////////////
    // Test 2: Configuring INT waiting for NEMO_setup asserted  //
    /////////////////////////////////////////////////////////////
    $display("Executing Test 2");
    $display("Write to configure INT");
    wt_data = 16'h0D02;
    @(posedge clk);
    wrt = 1;
    @(posedge clk);
    wrt = 0;

    $display("Waiting NEMO_setup");
    @(posedge iNEMO.NEMO_setup);

    $display("Test 2 PASSED");

    $display("Waiting for INT");
    wait_for_sig(INT, 100000, 1);

    ///////////////////////////////////////////////////////////////
    // Test 3: Reading the low_byte of Yaw first time index     //
    // Also checking for INT deassertion after yaw read        //
    ////////////////////////////////////////////////////////////
    $display("Executing Test 2");

    wt_data = 16'hA6xx;
    @(posedge clk);
    wrt = 1;
    @(posedge clk);
    wrt = 0;

    $display("Waiting for sig done");
    wait_for_sig(done, 100000, 1);

    if(rd_data[7:0] !== 8'h8d) begin
        $display("Test 3 FAILED" );
        $display("register contained: %0h", rd_data);
        $display("register should contain: %0h", 8'h8d);
        $stop();
    end

    // Checking for INT deasserted
    if(INT !== 1'b0)begin
      $display("Test 4 FAILED" );
      $display("INT not deasserted after read");
      $stop();
    end

    $display("Waiting for INT");
    wait_for_sig(INT, 100000, 1);

    $display("Test 3 PASSED");

    ///////////////////////////////////////////////////////////////
    // Test 4: Reading the high_byte of Yaw second time index   //
    /////////////////////////////////////////////////////////////
    $display("Executing Test 4");
    wt_data = 16'hA7xx;
    @(posedge clk);
    wrt = 1;
    @(posedge clk);
    wrt = 0;

    $display("Waiting for sig done");
    wait_for_sig(done, 100000, 1);
    if(rd_data[7:0] !== 8'hcd) begin
        $display("Test 4 FAILED" );
        $display("register contained: %0h", rd_data);
        $display("register should contain: %0h", 8'hcd);
        $stop();
    end

    $display("Test 4 PASSED");

    ///////////////////////////////////////////////////////////////
    // Test 5: Reading the low_byte of Yaw second time index     //
    /////////////////////////////////////////////////////////////
    $display("Executing Test 5");
    wt_data = 16'hA6xx;
    @(posedge clk);
    wrt = 1;
    @(posedge clk);
    wrt = 0;

    $display("Waiting for sig done");
    wait_for_sig(done, 100000, 1);
    if(rd_data[7:0] !== 8'h3d) begin
        $display("Test 5 FAILED" );
        $display("register contained: %0h", rd_data);
        $display("register should contain: %0h", 8'h3d);
        $stop();
    end

    $display("Waiting for INT");
    wait_for_sig(INT, 100000, 1);

    ///////////////////////////////////////////////////////////////
    // Test 6: Reading the high_byte of Yaw third time index   //
    /////////////////////////////////////////////////////////////
    $display("Executing Test 6");
    wt_data = 16'hA7xx;
    @(posedge clk);
    wrt = 1;
    @(posedge clk);
    wrt = 0;

    $display("Waiting for sig done");
    wait_for_sig(done, 100000, 1);
    if(rd_data[7:0] !== 8'hd2) begin
        $display("Test 6 FAILED" );
        $display("register contained: %0h", rd_data);
        $display("register should contain: %0h", 8'hd2);
        $stop();
    end

    $display("Test 6 PASSED");

    ///////////////////////////////////////////////////////////////
    // Test 7: Reading the low_byte of Yaw third time index     //
    /////////////////////////////////////////////////////////////
    $display("Executing Test 7");
    wt_data = 16'hA6xx;
    @(posedge clk);
    wrt = 1;
    @(posedge clk);
    wrt = 0;

    $display("Waiting for sig done");
    wait_for_sig(done, 100000, 1);
    if(rd_data[7:0] !== 8'haa) begin
        $display("Test 7 FAILED" );
        $display("register contained: %0h", rd_data);
        $display("register should contain: %0h", 8'haa);
        $stop();
    end
    
    $display("Waiting for INT");
    wait_for_sig(INT, 100000, 1);

    $display("Test 7 PASSED");

    $display("Yahoo, all tests passed!");
    $stop();
end

always 
    #10 clk <= ~clk;

endmodule