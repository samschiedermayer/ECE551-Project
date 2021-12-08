module PWM11(
	input clk,
	input rst_n,
	input [10:0] duty,
	output logic PWM_sig,
	output logic PWM_sig_n
);

logic [10:0] cnt;

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		cnt <= 11'h000;
	end else begin
		cnt <= cnt + 1;
	end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
	  PWM_sig <= 1'b0;
	end else begin
	  PWM_sig <= cnt < duty;
	end
end

assign PWM_sig_n = ~PWM_sig;

endmodule