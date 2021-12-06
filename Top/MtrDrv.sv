module MtrDrv(
    input logic clk,
    input logic rst_n,
    input logic [10:0] lft_spd,
    input logic [10:0] rght_spd,
    output logic lftPWM1,
    output logic lftPWM2,
    output logic rghtPWM1,
    output logic rghtPWM2
);

logic [10:0] l_duty, r_duty;

assign l_duty = lft_spd + 11'h400;
assign r_duty = rght_spd + 11'h400;

PWM11 l_pwm(.clk(clk),.rst_n(rst_n),.duty(l_duty),.PWM_sig(lftPWM2),.PWM_sig_n(lftPWM1));
PWM11 r_pwm(.clk(clk),.rst_n(rst_n),.duty(r_duty),.PWM_sig(rghtPWM2),.PWM_sig_n(rghtPWM1));

endmodule
