module TourLogic_tb;

logic clk, rst_n, go, done;
logic [2:0] x_start, y_start, move;
logic [4:0] indx;

TourLogic iDut(.clk(clk),.rst_n(rst_n),.go(go),.done(done),
             .x_start(x_start),.y_start(y_start),.move(move),.indx(indx));

reg [7:0] expected[0:23][0:4][0:4];

logic tb_err;
initial begin
  tb_err = 0;

  $readmemh("moves_expected.hex",expected);

  clk   = 0;
  rst_n = 0;

  go      = 0;
  indx    = 0;

  @(negedge clk);
  rst_n = 1;

  for (int i = 0; i < 5; i++) begin : outerloop
    for (int j = 0; j < 5; j++) begin : innerloop

      // skip inputs with no solution
      if (i[0] != j[0])
        continue;

      @(negedge clk);
      x_start = i;
      y_start = j;
      go = 1;
      @(negedge clk);
      go = 0;

      $display("start: (%d, %d)",i,j);

      fork: timeout_done
        begin
          @(posedge done);
          disable timeout_done;
        end
        begin
          repeat (20000000) @(posedge clk);
          $display("Error, timed out waiting for done");
          disable timeout_done;
        end
      join
      
      for (indx = 0; indx < 24; indx++) begin
        //#1 $display("move %d; val: %d, exp: %d",indx,move,expected[i][j][indx]);
        #1 $display("move %d; val: %d",indx,move);
      end

    end
  end
  $stop();
end

always #1 clk = ~clk;

endmodule

