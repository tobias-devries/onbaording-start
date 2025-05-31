`default_nettype none


module spi_peripheral(
     input wire clk,
    input wire rst_n,
    input wire[2:0] ui_in,
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

reg [2:0] syncbit1, syncbit2, syncbit3;
reg syncedsclk, syncedcs, syncedcopi;
reg [15:0] addreg;
reg [4:0] count;
reg [3:0] index;
reg prev_sclk, prev_cs;
reg transaction_processed;
reg transaction_ready;

always@(posedge clk or negedge rst_n)begin
if(~rst_n)begin
syncbit1 <= 3'b000;
syncbit2 <= 3'b000;
syncbit3 <= 3'b000;
syncedsclk <= 1'b0;
syncedcopi <= 1'b0;
syncedcs <= 1'b1;
end else begin
syncbit1<=ui_in;
syncbit2<=syncbit1;
syncbit3<=syncbit2;
syncedsclk<=syncbit3[0];
syncedcopi<=syncbit3[1];
syncedcs<=syncbit3[2];
end
end



always@(posedge clk or negedge rst_n)begin
 if(~rst_n)begin   
    transaction_ready <= 1'b0;
    addreg <= 16'd0;
    count <= 5'd0;
    index<=4'b1111;
    prev_sclk <= 1'b0;
    prev_cs <= 1'b1;
 end else begin
   if (syncedcs && transaction_processed)begin
        transaction_ready <= 1'b0;
        addreg<=16'd0;
        count<=5'd0;
        index<=4'b1111;
        prev_sclk <= 1'b0;
    end else if(~syncedcs && prev_cs)begin                          
      transaction_ready <= 1'b1;
      prev_sclk <= 1'b0;
      transaction_processed <= 1'b0; 
      count <= 5'd0;
      index<=4'b1111;
    end else if(~syncedcs) begin                  
        if(syncedsclk & ~prev_sclk)begin          
        addreg[index] <= syncedcopi;              
        if(count < 16)begin
        count <= count + 1;                                
        index <= index - 1;
        end
        end
        prev_sclk <= syncedsclk;                 
  end
    
  prev_cs <= syncedcs;
 end
end


always@(posedge clk or negedge rst_n)begin
if(~rst_n)begin
        transaction_processed <= 1'b0;
        en_reg_out_7_0 <= 8'd0;
        en_reg_out_15_8 <= 8'd0;
        en_reg_pwm_7_0 <= 8'd0;
        en_reg_pwm_15_8 <= 8'd0;
        pwm_duty_cycle <= 8'd0;
end else begin
if(addreg[15] && transaction_ready && count == 16) begin
    case (addreg[14:8])
    7'b0000000: en_reg_out_7_0<=addreg[7:0];
    7'b0000001: en_reg_out_15_8<=addreg[7:0];
    7'b0000010: en_reg_pwm_7_0<=addreg[7:0];
    7'b0000011: en_reg_pwm_15_8<=addreg[7:0];
    7'b0000100: pwm_duty_cycle<=addreg[7:0];
    default: begin
    end
    endcase
    transaction_processed <= 1'b1;
end
end
end


endmodule