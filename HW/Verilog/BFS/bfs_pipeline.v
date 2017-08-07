`timescale 1ns / 1ps

module bfs_pipeline(
    clk,
    rst,
	last_input_in,
    word_in,
	word_in_valid,
    word_in_th,
    control,
    current_level,
    last_input_out,
	control_out,
	word_out,
    valid_out,
	word_in_valid_out,
    word_in_th_out);

parameter ADDR_W = 4;               // this value decides how many vertices in a BRAM
localparam DEPTH = (2**ADDR_W);
parameter stage_no = 2; // 2^stage_no=4 stages
localparam total_stages_in_ten = (2**stage_no); 
parameter pipeline_id = 0; 


input   clk, rst;
input   [511:0]              word_in;
input   [1:0]   control;
input   [7:0]   current_level;     
input	[0:0]	word_in_valid;
input	[31:0]	word_in_th;
input	[0:0]	last_input_in;

output  [31:0]          word_out;
output                  valid_out;
output	[0:0]	last_input_out;
output	[1:0]	control_out;

wire  [31:0]    word_out_wire       [total_stages_in_ten-2:0];
wire            valid_out_wire      [total_stages_in_ten-2:0];
wire  [511:0]    word_in_out_wire    [total_stages_in_ten-2:0];
wire  [1:0]          control_out_wire    [total_stages_in_ten-2:0];
wire  [0:0]          last_input_wire    [total_stages_in_ten-2:0];
wire  [0:0]		word_in_valid_wire [total_stages_in_ten-2:0];
wire  [31:0]		word_in_th_wire [total_stages_in_ten-2:0];

output  reg [0:0]		word_in_valid_out;  // from afu-io
output  reg [31:0]		word_in_th_out;     // from afu-core
    
    pipeline_start #(.ADDR_W(ADDR_W), .stage_no(stage_no), .pipeline_id(pipeline_id))
	p_start (
	    .clk(clk),
        .rst(rst),
		.last_input_in(last_input_in),
        .word_in(word_in),
		.word_in_valid(word_in_valid),
		.word_in_th(word_in_th),
        .control(control),
        .current_level(current_level),
        .control_out(control_out_wire[0]),
        .word_in_out(word_in_out_wire[0]),
        .last_input_out(last_input_wire[0]),
		.word_out(word_out_wire[0]),
        .valid_out(valid_out_wire[0]),
		.word_in_valid_out(word_in_valid_wire[0]),
		.word_in_th_out(word_in_th_wire[0])
	);
	
	genvar numstg;
    generate
        for(numstg=1; numstg < total_stages_in_ten-1; numstg = numstg+1)
        begin: elements
            pipeline_mid #(.ADDR_W(ADDR_W), .stage_no(stage_no), .my_stage_id(numstg), .pipeline_id(pipeline_id))
            p_mid (              
               .clk(clk),
               .rst(rst),
			   .last_input_in(last_input_wire[numstg-1]),
               .word_in(word_in_out_wire[numstg-1]),
			   .word_in_valid(word_in_valid_wire[numstg-1]),
			   .word_in_th(word_in_th_wire[numstg-1]),
               .word_out_previous(word_out_wire[numstg-1]),
               .valid_out_previous(valid_out_wire[numstg-1]),
               .control(control_out_wire[numstg-1]),
               .current_level(current_level),
               .control_out(control_out_wire[numstg]),
               .word_in_out(word_in_out_wire[numstg]),
			   .last_input_out(last_input_wire[numstg]),
               .word_out(word_out_wire[numstg]),
               .valid_out(valid_out_wire[numstg]),
			   .word_in_valid_out(word_in_valid_wire[numstg]),
			   .word_in_th_out(word_in_th_wire[numstg])	
            );         
        end
    endgenerate
	
    pipeline_end #(.ADDR_W(ADDR_W),.stage_no(stage_no), .pipeline_id(pipeline_id)) 
    p_end ( 
        .clk(clk),
        .rst(rst),
		.last_input_in(last_input_wire[total_stages_in_ten-2]),
        .word_in(word_in_out_wire[total_stages_in_ten-2]),
		.word_in_valid(word_in_valid_wire[total_stages_in_ten-2]),
		.word_in_th(word_in_th_wire[total_stages_in_ten-2]),
        .word_out_previous(word_out_wire[total_stages_in_ten-2]),
        .valid_out_previous(valid_out_wire[total_stages_in_ten-2]),
        .control(control_out_wire[total_stages_in_ten-2]),
        .current_level(current_level),
        .last_input_out(last_input_out),
		.control_out(control_out),
		.word_out(word_out),
        .valid_out(valid_out),
		.word_in_valid_out(word_in_valid_out),
		.word_in_th_out(word_in_th_out)
    );

    
endmodule



