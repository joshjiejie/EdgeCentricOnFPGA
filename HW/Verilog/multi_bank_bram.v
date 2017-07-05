`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/17/2016 03:14:12 PM
// Design Name: 
// Module Name: multi_bank_bram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module multi_bank_bram(
	data_in,	// W
	r_addr,	// R
	w_addr,	// W
	we_in,	// W
	clk,
	data_out	// R
	);
parameter DATA_W = 8;	
parameter ADDR_W = 10;
localparam DEPTH = (2**ADDR_W);

input [511:0] data_in;
input [ADDR_W+5:0] r_addr;
input [ADDR_W-1:0] w_addr;
input we_in;
input clk;
output reg [DATA_W-1:0] data_out;

reg  [5:0] r_addr_buff;   

wire [DATA_W-1:0] bank [63:0];


    genvar numstg;
    generate
        for(numstg=0; numstg < 64; numstg = numstg+1)
        begin: elements
            bram #(.DATA_W(DATA_W),.ADDR_W(ADDR_W))
            banks (              
                  .data_in(data_in[numstg*8+7:numstg*8]), 
                  .r_addr(r_addr[ADDR_W+5:6]),
                  .w_addr(w_addr),
                  .we_in(we_in),
                  .clk(clk),
                  .data_out(bank[numstg])              
            );         
        end
    endgenerate
    
    always @(posedge clk) begin     
       data_out <= bank[r_addr_buff] ;
       r_addr_buff <= r_addr[5:0];
    end    
         		
endmodule