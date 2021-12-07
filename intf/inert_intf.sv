//////////////////////////////////////////////////////
// Interfaces with ST 6-axis inertial sensor.  In  //
// this application we only use Z-axis gyro for   //
// heading of robot.  Fusion correction comes    //
// from "gaurdrail" signals lftIR/rghtIR.       //
/////////////////////////////////////////////////
module inert_intf(clk,rst_n,strt_cal,cal_done,heading,rdy,lftIR,
                  rghtIR,SS_n,SCLK,MOSI,MISO,INT,moving);

  parameter FAST_SIM = 1;	// used to speed up simulation
  
  input clk, rst_n;
  input MISO;					// SPI input from inertial sensor
  input INT;					// goes high when measurement ready
  input strt_cal;				// initiate claibration of yaw readings
  input moving;					// Only integrate yaw when going
  input lftIR,rghtIR;			// gaurdrail sensors
  
  output cal_done;				// pulses high for 1 clock when calibration done
  output signed [11:0] heading;	// heading of robot.  000 = Orig dir 3FF = 90 CCW 7FF = 180 CCW
  output rdy;					// goes high for 1 clock when new outputs ready (from inertial_integrator)
  output SS_n,SCLK,MOSI;		// SPI outputs
 

  ////////////////////////////////////////////
  // Declare any needed internal registers //
  //////////////////////////////////////////
  logic c_y_l, c_y_h;
  logic [7:0] yaw_L, yaw_H;
  logic [15:0] inert_data;
  always_ff @(posedge clk)
    if (c_y_l)
      yaw_L <= inert_data[7:0];
  always_ff @(posedge clk)
    if (c_y_h)
      yaw_H <= inert_data[7:0];

  logic signed [15:0] yaw_rt;
  assign yaw_rt = {yaw_H,yaw_L};

  reg [15:0] timer;
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      timer <= 16'h0;
    else
      timer <= timer + 1;

  wire INT_stable;
  reg last_int, cur_int;
  always_ff @(posedge clk) begin
    cur_int <= INT;
    last_int <= cur_int;
  end
  
  //////////////////////////////////////////////
  // Declare outputs of SM are of type logic //
  ////////////////////////////////////////////
  logic vld, wrt;
  logic [15:0] cmd;
  
  
  ///////////////////////////////////////
  // Create enumerated type for state //
  /////////////////////////////////////
  typedef enum logic [2:0] { INIT1, INIT2, INIT3, INIT4, IDLE, READL, READH, VLD } inert_intf_state_t;
  
  ////////////////////////////////////////////////////////////
  // Instantiate SPI monarch for Inertial Sensor interface //
  //////////////////////////////////////////////////////////
  SPI_mnrch iSPI(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),
                 .MISO(MISO),.MOSI(MOSI),.wrt(wrt),.done(done),
				 .rd_data(inert_data),.wt_data(cmd));
				  
  ////////////////////////////////////////////////////////////////////
  // Instantiate Angle Engine that takes in angular rate readings  //
  // and acceleration info and produces a heading reading         //
  /////////////////////////////////////////////////////////////////
  inertial_integrator #(FAST_SIM) iINT(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal),.vld(vld),
                           .rdy(rdy),.cal_done(cal_done), .yaw_rt(yaw_rt),.moving(moving),.lftIR(lftIR),
                           .rghtIR(rghtIR),.heading(heading));

  assign INT_stable = cur_int & ~last_int;

  inert_intf_state_t state, nxt_state;
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      state <= INIT1;
    else
      state <= nxt_state;

  always_comb begin
    nxt_state = state;
    c_y_l = 0;
    c_y_h = 0;
    vld = 0;
    wrt = 0;
    cmd = 16'h0000;
    case (state)

      INIT1: begin
        cmd = 16'h0D02;
        if (&timer) begin
          wrt = 1;
          nxt_state = INIT2;
        end
      end
  
      INIT2: begin
        cmd = 16'h1160;
        if (done) begin
          wrt = 1;
  	  nxt_state = INIT3;
        end
      end
  
      INIT3: begin
        cmd = 16'h1440;
        if (done) begin
          wrt = 1;
  	  nxt_state = INIT4;
        end
      end
  
      INIT4: if (done) begin
        nxt_state = IDLE;
      end
  
      IDLE: begin
        cmd = 16'hA600;
        if (INT_stable) begin
          wrt = 1;
  	  nxt_state = READL;
        end
      end
  
      READL: begin      
        if (done) begin
          cmd = 16'hA700;
          c_y_l = 1;
          wrt = 1;
  	  nxt_state = READH;
        end
      end
  
      READH: begin
        if (done) begin
          c_y_h = 1;
          nxt_state = VLD;
        end
      end
      
      default: begin //VLD
        vld = 1;
        nxt_state = IDLE;
      end

    endcase
  end
 
endmodule
	  
