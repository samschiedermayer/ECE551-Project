module SPI_mnrch(
    input clk, rst_n,
    input MISO,
    input wrt,
    input [15:0] wt_data,
    output logic SS_n, SCLK, MOSI,
    output logic done,
    output [15:0] rd_data
);
///////////////////////////////////////////////////////////////
// Local Signal Declarations                                //        
/////////////////////////////////////////////////////////////
logic MISO_smpl, smpl, init, shft, ld_SCLK, clr, set_done, rst_cnt, set_SS_n, rise_imm, fall_imm, done15;
logic [15:0] shft_reg;
logic [3:0] bit_cntr;
logic [4:0] SCLK_div;

///////////////////////////////////////////////////////////////
// rd_data only valid when done                             //        
/////////////////////////////////////////////////////////////
assign rd_data = shft_reg;

///////////////////////////////////////////////////////////////
// SCLK_div logic                                           //        
/////////////////////////////////////////////////////////////
always_ff @(posedge clk) begin
    if(ld_SCLK)
        SCLK_div <= 5'b10111;
    else
        SCLK_div <= SCLK_div + 1;
end

assign SCLK = SCLK_div[4];

///////////////////////////////////////////////////////////////
// MISO smpl logic                                          //        
/////////////////////////////////////////////////////////////
always_ff @(posedge clk) begin
    if(smpl)
        MISO_smpl <= MISO;
end

///////////////////////////////////////////////////////////////
// MOSI output                                              //        
/////////////////////////////////////////////////////////////
always_ff @(posedge clk) begin
    if(init)
        shft_reg <= wt_data;
    else if(shft)
        shft_reg <= {shft_reg[14:0], MISO_smpl};

end

assign MOSI = shft_reg[15];

///////////////////////////////////////////////////////////////
// Bit counter                                              //        
/////////////////////////////////////////////////////////////
always_ff @(posedge clk) begin
    if(init)
        bit_cntr <= 4'b0000;
    else if(shft)
        bit_cntr <= bit_cntr + 1;
end

assign rise_imm = SCLK_div == 5'b01111;
assign fall_imm = &SCLK_div;

assign done15 = &bit_cntr;

///////////////////////////////////////////////////////////////
// SS_n                                                     //        
/////////////////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n)begin
    if(!rst_n)
        SS_n <= 1;
    else if(init)
        SS_n <= 0;
    else if(set_done)
        SS_n <= 1;
end

///////////////////////////////////////////////////////////////
// Done Logic                                               //        
/////////////////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n)begin
    if(!rst_n)
        done <= 0;
    else if(init)
        done <= 0;
    else if(set_done)
        done <= 1;
end

///////////////////////////////////////////////////////////////
// State Machine State Declarations                         //
/////////////////////////////////////////////////////////////
typedef enum reg [1:0] {IDLE, FP, TRANS, BP} state_t;

state_t state, nxt_state;

///////////////////////////////////////////////////////////////
// State Machine Flipity Flopity                            //
/////////////////////////////////////////////////////////////
always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;

///////////////////////////////////////////////////////////////
// State Machine Output Logic                               //
/////////////////////////////////////////////////////////////
always_comb begin
    // defaulting outputs
    init = 0;
    rst_cnt = 0;
    shft = 0;
    smpl = 0;
    ld_SCLK = 0;
    set_done = 0;
    nxt_state = state;

    case(state)
        IDLE: begin
            ld_SCLK = 1;
            if(wrt) begin
                init = 1;
                nxt_state = FP;
            end
        end
        FP: 
            if(fall_imm)
                nxt_state = TRANS;
        TRANS: begin
            smpl = rise_imm;
            shft = fall_imm;
            if(done15)
                nxt_state = BP;
        end
        BP: begin
            smpl = rise_imm;
            shft = fall_imm;
            if(fall_imm) begin
                smpl = 1;
                shft = 1;
                ld_SCLK = 1;
                set_done = 1;
                nxt_state = IDLE;
            end
        end
        default:
            nxt_state = IDLE;
    endcase
end

endmodule