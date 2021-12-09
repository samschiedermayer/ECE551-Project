package tb_tasks;

  task automatic wait_for_sig(ref sig, input int clks_to_wait, input int pos);
    fork
      begin : timeout
	repeat (clks_to_wait) @(posedge clk);
	$display("TEST FAILED");
	$display("ERROR: Timed out waiting for signal, %d clock cycles", clks_to_wait);
	$stop();
      end
      begin
	if (pos === 1) begin
	  $display("Waiting for posedge");
	end else begin
	  $display("Waiting for negedge");
	  @(negedge sig);
	end
	disable timeout;
      end
    join
  endtask

endpackage
