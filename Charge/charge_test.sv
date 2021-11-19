module charge_test();

///////////////////////////////////////////////////////////////
// Declare signals                                          //
/////////////////////////////////////////////////////////////
logic clk, rst_n;
logic GO, piezo, piezo_n;
logic released;
logic FAST_SIM = 1'b0;


///////////////////////////////////////////////////////////////
// Instantiate the DUT and SPI_iNEMO1                       //
/////////////////////////////////////////////////////////////
charge #(FAST_SIM)iDUT_Charge(.clk(clk), .rst_n(rst_n), .go(released), .piezo(piezo), .piezo_n(piezo_n));
PB_release iDUT_PB(.PB(GO), .released(released));
reset_synch iDUT_reset(.rst_n(RST_n), .clk(clk), .rst_n(rst_n));

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
    
    wait_for_sig(done, 100000, 1);
    if(rd_data !== 8'h6A) begin
        $display("Test 1 FAILED" );
        $stop();
    end
    $display("Test 1 PASSED");

    // ///////////////////////////////////////////////////////////////
    // // Test 2: Configuring INT waiting for NEMO_setup asserted  //
    // /////////////////////////////////////////////////////////////
    // $display("Executing Test 2");
    
    // $display("Waiting NEMO_setup");

    // $display("Test 2 PASSED");

    // wait_for_sig(INT, 100000, 1);

    // ///////////////////////////////////////////////////////////////
    // // Test 3: Reading the low_byte of Yaw first time index     //
    // // Also checking for INT deassertion after yaw read        //
    // ////////////////////////////////////////////////////////////
    // $display("Executing Test 3");

    // $display("Waiting for sig done");
    // wait_for_sig(done, 100000, 1);

    // if(rd_data[7:0] !== 8'h8d) begin
    //     $display("Test 3 FAILED" );
    //     $stop();
    // end

    // $display("Test 3 PASSED");

    // ///////////////////////////////////////////////////////////////
    // // Test 4: Reading the high_byte of Yaw second time index   //
    // /////////////////////////////////////////////////////////////
    // $display("Executing Test 4");

    // if(rd_data[7:0] !== 8'hcd) begin
    //     $display("Test 4 FAILED" );
    //     $stop();
    // end

    // $display("Test 4 PASSED");

    // ///////////////////////////////////////////////////////////////
    // // Test 5: Reading the low_byte of Yaw second time index     //
    // /////////////////////////////////////////////////////////////
    // $display("Executing Test 5");

    // if(rd_data[7:0] !== 8'h3d) begin
    //     $display("Test 5 FAILED" );
    //     $stop();
    // end

    // ///////////////////////////////////////////////////////////////
    // // Test 6: Reading the high_byte of Yaw third time index   //
    // /////////////////////////////////////////////////////////////
    // $display("Executing Test 6");
 
    // if(rd_data[7:0] !== 8'hd2) begin
    //     $display("Test 6 FAILED" );
    //     $stop();
    // end

    // $display("Test 6 PASSED");

    // ///////////////////////////////////////////////////////////////
    // // Test 7: Reading the low_byte of Yaw third time index     //
    // /////////////////////////////////////////////////////////////
    // $display("Executing Test 7");

    // if(rd_data[7:0] !== 8'haa) begin
    //     $display("Test 7 FAILED" );
    //     $stop();
    // end

    $display("Test 7 PASSED");

    $display("Yahoo, all tests passed!");
    $stop();
end

always 
    #10 clk <= ~clk;

endmodule