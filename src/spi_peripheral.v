`default_nettype none


module spi_peripheral(
     input wire clk,
    input wire rst_n,
    input wire[2:0] ui_in,
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle;
);

reg [2:0] syncbit1, syncbit2, syncbit3;
reg syncedsclk, syncedcs, syncedcopi;
reg [15:0] addreg;
reg [4:0] count;
reg prev_sclk = 1'b0;
reg transaction_processed = 1'b0;
reg transaction_ready = 1'b0;

always@(posedge clk)begin
syncbit1<=ui_in;
syncbit2<=syncbit1;
syncbit3<=syncbit2;
syncedsclk<=syncbit3[0];
syncedcopi<=syncbit3[1];
syncedcs<=syncbit3[2];
end



always@(posedge clk or negedge rst_n)begin
 if(rst_n)begin   
     transaction_processed <= 1'b0;
    transaction_ready <= 1'b0;
    addreg <= 16'd0;
    count <= 1'd0;
    prev_sclk <= 1'b0;

    end
 end else begin
   if (syncedcs && transaction_processed)begin
        transaction_processed <= 1'b0;
        transaction_ready <= 1'b0;
        addreg<=16'd0;
        count<=1'd0;
    end else if(syncedcs)begin                           //if chip select is HIGH
      transaction_ready <= 1'b1;
    end else if(~syncedcs) begin                              //if chip select is LOW
        if(syncedsclk & ~prev_sclk)begin                //if its an edge
        addreg[count] <= syncedcopi;              //set the temp register to a bit count to the copi input
        count++;                                //increases the count
        end
        prev_sclk <= syncedsclk;                 //sets current clock to previous clock
        transaction_ready <= 1'b0;
 end
end


always@(posedge clk or negedge rst_n)begin
if(rst_n)begin
        transaction_processed <= 1'b0;
        en_reg_out_7_0 <= 8'd0;
        en_reg_out_15_8 <= 8'd0;
        en_reg_pwm_7_0 <= 8'd0;
        en_reg_pwm_15_8 <= 8'd0;
        pwm_duty_cycle <= 8'd0;

end else begin
if(addreg[0] && transaction_ready) begin
    casez (addreg)
    16'bx0000000xxxxxxxxx: begin
        en_reg_out_7_0<=addreg[7:0];
    end
    16'bx0000001xxxxxxxxx: begin
        en_reg_out_15_8<=addreg[7:0];
    end
    16'bx0000010xxxxxxxxx: begin
        en_reg_pwm_7_0<=addreg[7:0];
    end 
    16'bx0000011xxxxxxxxx: begin
        en_reg_pwm_15_8<=addreg[7:0];
    end
    16'bx0000100xxxxxxxxx: begin
        pwm_duty_cycle<=addreg[7:0];
    end 
    default: begin
    end
    endcase
    transaction_processed <= 1'b1;
end
end
end


endmodule