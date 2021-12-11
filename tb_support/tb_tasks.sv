package tb_tasks;

  //task automatic check_equal (input [31:0] check_val, input [31:0] correct_val, input string message);
  //  if (check_val !== correct_val) begin
  //    tb_err = 1;
  //    $display(message);
  //    $display("Expected value: %h, Actual value: %h", correct_val,check_val);
  //  end
  //endtask : check_equal

  //task automatic check_not_equal (input [31:0] check_val, input [31:0] correct_val, input string message);
  //  if (check_val === correct_val) begin
  //    tb_err = 1;
  //    $display(message);
  //    $display("Expected value: %h, Actual value: %h", correct_val,check_val);
  //  end
  //endtask : check_not_equal

  // general tasks
  task automatic err_on_cond_true (
    input logic condition,
    ref logic tb_err,
    input string err_msg 
  );
    if (condition) begin
      tb_err = 1;
      $display(err_msg);
    end
  endtask : err_on_cond_true

  task automatic err_on_cond_false (
    input logic condition,
    ref logic tb_err,
    input string err_msg
  );
    if (!condition) begin
      tb_err = 1;
      $display(err_msg);
    end
  endtask : err_on_cond_false

  task automatic wait_for_sig(
    ref logic clk, sig,
    input int clks_to_wait,
    input logic pos,
    input string err_msg,
    inout logic tb_err,
    inout int cycles
  );
    cycles = 0;
    fork
      begin : timeout
	      repeat (clks_to_wait) begin
          @(posedge clk);
          cycles = cycles + 1;
        end
       	tb_err = 1;	
      	$display("ERROR: %s, timed out after %0d clk cycles",err_msg,clks_to_wait);
        disable timeout;
      end
      begin
      	if (pos === 1) begin
          @(posedge sig);
      	end else begin
      	  @(negedge sig);
      	end
      	disable timeout;
      end
    join
    $display("cycles: %0d",cycles);
  endtask : wait_for_sig

  // tourlogic specific tasks
  task automatic initialize (
    ref logic lftPWM1, rghtPWM1, lftPWM2, rghtPWM2, NEMO_setup, clk,
    inout logic tb_err
  );
    // Add code
  endtask : initialize

  task automatic sendCommand(
    ref logic clk, done_sig, tb_err
  );
    // Add code
  endtask : sendCommand

  task automatic checkPositiveAck();
    // Add code
  endtask : checkPositiveAck

  task automatic moveWestOneSquare ();
    // Add code
  endtask : moveWestOneSquare

endpackage
