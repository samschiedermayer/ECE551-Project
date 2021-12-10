package tb_tasks;

  logic tb_err;

  task automatic check_equal (input [31:0] check_val, input [31:0] correct_val, input string message);
    if (check_val !== correct_val) begin
      tb_err = 1;
      $display(message);
      $display("Expected value: %h, Actual value: %h", correct_val,check_val);
    end
  endtask : check_equal

  task automatic check_not_equal (input [31:0] check_val, input [31:0] correct_val, input string message);
    if (check_val === correct_val) begin
      tb_err = 1;
      $display(message);
      $display("Expected value: %h, Actual value: %h", correct_val,check_val);
    end
  endtask : check_not_equal

  task automatic check_condition_true (input condition, input string message);
    if (!condition) begin
      tb_err = 1;
      $display(message);
      $display("Condition was false");
    end
  endtask : check_condition_true

  task automatic check_condition_false (input condition, input string message);
    if (!condition) begin
      tb_err = 1;
      $display(message);
      $display("Condition was true");
    end
  endtask : check_condition_false

  task automatic wait_for_sig(ref clk, ref sig, input int clks_to_wait, input int pos);
    fork
      begin : timeout
	repeat (clks_to_wait) @(posedge clk);
	tb_err = 1;	
	$display("TEST FAILED");
	$display("ERROR: Timed out waiting for signal, %d clock cycles", clks_to_wait);
	$stop();
      end
      begin
	if (pos === 1) begin
	  $display("Waiting for posedge");
	  @(posedge sig);
	end else begin
	  $display("Waiting for negedge");
	  @(negedge sig);
	end
	disable timeout;
      end
    join
  endtask : wait_for_sig

  task automatic initialize (ref clk, ref NEMO_setup, ref PWM_sig_1); // TODO: Add PWM signals to check
    // Add code
  endtask : initialize

  task automatic sendCommand(ref clk, ref done_sig, );
    // Add code
  endtask : sendCommand

  task automatic checkPositiveAck();
    // Add code
  endtask : checkPositiveAck

  task automatic moveWestOneSquare ();
    // Add code
  endtask : moveWest

endpackage
