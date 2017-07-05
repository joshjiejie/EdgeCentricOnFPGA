`timescale 1ns / 1ps

module bfs_pipeline(
    clk,
    rst,
	last_input_in,
    word_in,
    word_in_valid,
    control,
    current_level,
    control_out,
    last_input_out,
	word_out,
    valid_out,
	word_in_valid_out
 );

parameter ADDR_W = 2;               // this value decides how many vertices in a BRAM
localparam DEPTH = (2**ADDR_W);
parameter stage_no = 2; // 2^5=32 stages
localparam my_stage_id = 0;
parameter pipeline_id = 0; 

input   clk, rst;
input   [511:0]              word_in;
input   [0:0]        word_in_valid;
input   [1:0]               control;
input   [7:0]               current_level;     
input	[0:0]		last_input_in;


output	reg	[0:0]	last_input_out;
reg	[0:0]	last_input_buff;
reg	[0:0]	last_input_buff_2;

output  reg [31:0]          word_out;
output  reg                 valid_out;
output  reg [1:0]           control_out;
output  reg [0:0]			word_in_valid_out;  // from afu-io


wire   [7:0]                bram_out;
reg    [1:0]                     control_out_buff;
reg    [1:0]                     control_out_buff_2;

reg [0:0]		word_in_valid_buff;      
reg [0:0]		word_in_valid_buff_2;  
reg    [511:0]               word_in_out_buff;
reg    [511:0]               word_in_out_buff_2;    

   
reg   [stage_no+ADDR_W-1:0]         w_addr;
    
	multi_bank_bram #(.DATA_W(8),.ADDR_W(ADDR_W)) 
	bram0 (
	  .data_in(word_in), 
	  //.r_addr(word_in[63:32]),
	  .r_addr(word_in[ADDR_W+37+pipeline_id*64:32+pipeline_id*64]),
	  .w_addr(w_addr[ADDR_W-1:0]),
	  .we_in((control==1) & (word_in_valid)),
	  //.we_in(control),
	  .clk(clk),
	  //.rst(rst),
	  .data_out(bram_out)
	);
	
	always @(posedge clk) begin
        if (rst) begin
            word_out <=0;
            valid_out<=1'b0;
            control_out <= 0;
            control_out_buff <=0;
            control_out_buff_2 <=0;
			last_input_buff		<=0;
			last_input_buff_2	<=0;
			word_in_valid_buff <=0;  
			word_in_valid_buff_2 <=0; 
			word_in_valid_out <=0;
			word_in_out_buff <=0;
			word_in_out_buff_2 <=0;
			w_addr <= 0;
        end else begin     			
			control_out <= control_out_buff_2;	
			control_out_buff_2 <= control_out_buff;
			control_out_buff <= control;
			last_input_buff <= last_input_in;
			last_input_buff_2 <= last_input_buff;
			last_input_out <= last_input_buff_2;
		
			word_in_valid_out <= word_in_valid_buff_2;
			word_in_valid_buff_2 <= word_in_valid_buff;
			word_in_valid_buff <= word_in_valid;
			
			word_in_out_buff_2 <= word_in_out_buff;
			word_in_out_buff <= word_in;
			word_out <= 0; 
			valid_out <= 1'b0;
			w_addr <= w_addr;
			if((word_in_valid) & (control==1)) begin				
				w_addr <= w_addr+1'b1;
	        end

			if ((word_in_valid_buff_2)&(control==2)) begin     
				if(bram_out == current_level)   begin 	                
					 word_out  <= word_in_out_buff_2[31+pipeline_id*64:0+pipeline_id*64]; 
					 valid_out <= 1'b1; 
				end	                                                                                       
			end	
        end    
    end 
   
endmodule



