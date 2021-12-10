module PWM11_tb();	

logic clk,rst_n;		// clock and active low asynch reset
logic [10:0] duty;
logic PWM_sig, PWM_sig_n;

/////// Instantiate DUT /////////
PWM11 iDUT(.clk(clk), .rst_n(rst_n), .duty(duty), .PWM_sig(PWM_sig), .PWM_sig_n(PWM_sig_n));

always begin
  clk = 0;
  rst_n = 0;
  
  @(posedge clk);
  @(negedge clk) rst_n = 1;
  

// Test 1
// PWM_sig 100% duty cycle
duty = 11'h7FF;
repeat (10)@(posedge clk);
  if (!PWM_sig | PWM_sig_n) begin
		$display("ERROR: PWM_sig should be 1 and PWM_sig_n should be 0");
		$stop();
	end

// Test 2
// PWM_sig 0% duty cycle
  rst_n = 0;
  
  duty = 11'h000;
  @(posedge clk);
  @(negedge clk) rst_n = 1;
repeat (10)@(posedge clk);
  if (PWM_sig | !PWM_sig_n) begin
		$display("ERROR: PWM_sig should be 0 and PWM_sig_n should be 1");
		$stop();
	end


// Test 3
// PWM_sig 50% duty cycle
  rst_n = 0;
  
  duty = 11'h400;
  @(posedge clk);
  @(negedge clk) rst_n = 1;
  repeat (2048)@(posedge clk);

  $display("YAHOO!! test passed!\n");
  $stop();  

end

always
  #5 clk <= ~clk;		// toggle clock every 10 time units
  
endmodule