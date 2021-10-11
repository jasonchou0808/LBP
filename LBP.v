`timescale 1ns/10ps
module LBP (clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input clk;
input reset;
input gray_ready; 
input [7:0] gray_data;

output reg [13:0] gray_addr; //0~16383 address
output reg gray_req; //high get data
output reg [13:0] lbp_addr;
output reg lbp_valid;
output [7:0] lbp_data;
output reg finish;

reg [1:0] grayad_count;

reg [7:0] buffer0 [0:2];
reg [7:0] buffer1 [0:2];
reg [7:0] buffer2 [0:2];
//====================================================================
always @(posedge clk or posedge reset) begin //gray_req
    if(reset)
        gray_req <= 0;
    else if(gray_ready)
        gray_req <= 1;
    else 
        gray_req <= 0;
end

always @(posedge clk or posedge reset) begin //gray_addr
    if(reset)
        gray_addr <= 0;
    else if(gray_req)
        case(grayad_count)
            2'b00:
                gray_addr <= gray_addr + 128;
            2'b01:
                gray_addr <= gray_addr + 128;
            2'b10:
                gray_addr <= gray_addr - 255;
        endcase
    else 
        gray_addr <= 0;
end

always @(posedge clk) begin //grayad_count
    if(reset)
        grayad_count <= 0;
    else if(grayad_count == 2)
        grayad_count <= 0;
    else if(gray_req)
        grayad_count <= grayad_count + 1;
end

always @(posedge clk) begin //buffer0
    if (grayad_count == 0) begin
        buffer0[2] <= gray_data;
        buffer0[1] <= buffer0[2];
        buffer0[0] <= buffer0[1];
    end
end

always @(posedge clk) begin //buffer1
    if (grayad_count == 1) begin
        buffer1[2] <= gray_data;
        buffer1[1] <= buffer1[2];
        buffer1[0] <= buffer1[1];
    end
end

always @(posedge clk) begin //buffer2
    if (grayad_count == 2) begin
        buffer2[2] <= gray_data;
        buffer2[1] <= buffer2[2];
        buffer2[0] <= buffer2[1];
    end
end

assign lbp_data[0] = ((buffer0[0] < buffer1[1]) ? 0 : 1);
assign lbp_data[1] = ((buffer0[1] < buffer1[1]) ? 0 : 1);
assign lbp_data[2] = ((buffer0[2] < buffer1[1]) ? 0 : 1);
assign lbp_data[3] = ((buffer1[0] < buffer1[1]) ? 0 : 1);
assign lbp_data[4] = ((buffer1[2] < buffer1[1]) ? 0 : 1);
assign lbp_data[5] = ((buffer2[0] < buffer1[1]) ? 0 : 1);
assign lbp_data[6] = ((buffer2[1] < buffer1[1]) ? 0 : 1);
assign lbp_data[7] = ((buffer2[2] < buffer1[1]) ? 0 : 1);

always @(posedge clk or posedge reset) begin //lbp_addr
    if(reset)
        lbp_addr <= 126;
    else if(grayad_count == 2)
        lbp_addr <= lbp_addr + 1;
end

always @(posedge clk or posedge reset) begin //lbp_valid
    if(reset)
        lbp_valid <= 0;
    else if(grayad_count == 2 && lbp_addr % 128 != 126 && lbp_addr % 128 != 127)
        lbp_valid <= 1;
    else
        lbp_valid <= 0;
end

always @(posedge clk or posedge reset) begin //finish
    if(reset)
        finish <= 0;
    else if(lbp_addr == 16254)
        finish <= 1; 
    else
        finish <= 0;
end
//====================================================================
endmodule