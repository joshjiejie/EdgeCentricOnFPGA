`timescale 1ns / 1ps


module multi_bank_bram(
	data_in,	// W
	r_addr,	// R
	we_in,	// W
	clk,
	data_out	// R
	);
parameter DATA_W = 32;	
parameter ADDR_W = 12;
localparam DEPTH = (2**ADDR_W);

input [511:0] data_in;
input [ADDR_W+3:0] r_addr;
input we_in;
input clk;
output reg [DATA_W-1:0] data_out;

reg  [3:0] r_addr_buff;   

wire [DATA_W-1:0] bank [15:0];


    genvar numstg;
    generate
        for(numstg=0; numstg < 15; numstg = numstg+1)
        begin: elements
            bram #(.DATA_W(DATA_W),.ADDR_W(ADDR_W))
            banks (              
                  .data_in(data_in[numstg*32+31:numstg*32]), 
                  .r_addr(r_addr[ADDR_W+3:4]),
                  .w_addr(data_in[511:500]),
                  .we_in(we_in),
                  .clk(clk),
                  .data_out(bank[numstg])              
            );         
        end
    endgenerate
    
	bram #(.DATA_W(DATA_W),.ADDR_W(ADDR_W))
	bank15 (              
		  .data_in({12'h000, data_in[499:480]}), 
		  .r_addr(r_addr[ADDR_W+3:4]),
		  .w_addr(data_in[511:500]),
		  .we_in(we_in),
		  .clk(clk),
		  .data_out(bank[15])              
	);
			
	
    always @(posedge clk) begin     
       data_out <= bank[r_addr_buff] ;
       r_addr_buff <= r_addr[3:0];
    end    
         		
endmodule