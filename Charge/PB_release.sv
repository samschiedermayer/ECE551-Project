module PB_release(
    input PB,
    output released
);

logic ff_1, ff_2, ff_3;

always_ff begin
    if(rst_n)
        ff_1 = 1'b1;
        ff_2 = 1'b1;
        ff_3 = 1'b1;
    else
        ff_1 = PB;
        ff_2 = ff_1;
        ff_3 = ff_2;
end 

assign released = |ff_3 && ff_2;

endmodule