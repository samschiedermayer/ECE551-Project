module PID_tb();

///////////////////////////////////////////////////////////////
// Declare signals                                          //
/////////////////////////////////////////////////////////////
logic clk, rst_n, moving, err_vld;
logic signed [11:0] error;
logic [9:0] frwrd;
logic [10:0] lft_spd, rght_spd;
reg [24:0] stim[0:1999]; // 25-bit wide 2000 entry ROM
reg [21:0] resp[0:1999]; // 22-bit wide 2000 entry ROM

///////////////////////////////////////////////////////////////
// Instantiate the DUT                                      //
/////////////////////////////////////////////////////////////
PID DUT(.clk(clk), .rst_n(rst_n), .moving(moving), .err_vld(err_vld),
.error(error), .frwrd(frwrd), .lft_spd(lft_spd), .rght_spd(rght_spd));

///////////////////////////////////////////////////////////
// Task for waiting for signals or timing out the test  //
/////////////////////////////////////////////////////////
// task automatic wait_for_sig(ref sig, input int clks_to_wait, input int pos);
//   fork
//     begin : timeout
//       repeat(clks_to_wait) @(posedge clk);
//       $display("TEST FAILED");
//       $display("ERROR: timed out waiting for signal, %d clock cycles", clks_to_wait);
//       $stop();
//     end
//     begin
//       if(pos === 1) begin
//         $display("Waiting for posedge");
//         @(posedge sig);
//       end
//       else begin
//         $display("Waiting for negedge");
//         @(negedge sig);
//       end
//       disable timeout;
//     end
//   join
// endtask

///////////////////////////////////////////////////////////////
// Testing Logic                                            //
/////////////////////////////////////////////////////////////
initial begin
  ///////////////////////////////////////////////////////////////
  // Default values and DUT reset                             //
  /////////////////////////////////////////////////////////////
    $readmemh("PID_stim.hex", stim);
    $readmemh("PID_resp.hex", resp);
    clk = 0;
    @(posedge clk);
    // rst_n = 0;
    // @(posedge clk);
    // @(negedge clk);
    // rst_n = 1;

    ///////////////////////////////////////////////////////////////
    // Stimulus Testing                                         //
    /////////////////////////////////////////////////////////////
    $display("Executing Stimulus Testing");

    foreach (stim[i])begin
      rst_n = stim[i][24];
      moving = stim[i][23];
      err_vld = stim[i][22];
      error = stim[i][21:10];
      frwrd = stim[i][9:0];      
      repeat (10) @(negedge clk);

      if(lft_spd !== resp[i][21:11] && rght_spd !== resp[i][10:0]) begin
        $display("i: %h", i);

        $display("Observed lft_spd: %h", lft_spd);
        $display("Expected lft_spd: %h", resp[i][21:11]);

        $display("Observed rght_spd: %h", rght_spd);
        $display("Expected rght_spd: %h", resp[i][10:0]);

        $display("Tests Failed!");
        $stop();
      end
    end  
    
    $display("Yahoo, stimulus testing completed successfully!");
    $stop();
end

always 
    #10 clk <= ~clk;

endmodule