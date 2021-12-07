module reset_synch(
    input clk,
    input RST_n,
    output logic rst_n
);

logic first_flop;

always_ff @(negedge clk, negedge RST_n)
    if (!RST_n)
        first_flop <= 1'b0;
    else
		first_flop <= 1'b1;

always_ff @(negedge clk, negedge RST_n)
    if (!RST_n)
        rst_n <= 1'b0;
    else
		rst_n <= first_flop;

endmodule
