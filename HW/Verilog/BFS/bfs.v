`timescale 1ns / 1ps

module bfs(
    clk,
    rst,    
    last_input_in,
    word_in,
	word_in_valid,
    word_in_th,
    control,
    current_level,
    done,
    word_out, 
    valid_out
    //test_valid,
    //counter_out
 );

parameter ADDR_W = 4;               // this value decides how many vertices in a BRAM  
//total number of vertices stored on-chip: 2^ADDR * 2^stage_no
parameter stage_no = 2; // 2^stage_no=4 stages
parameter pipeline_no = 8;

input   clk, rst;
input   [511:0]              word_in;
input   [1:0]               control;
input	[0:0]	word_in_valid;
input	[31:0]	word_in_th;


input   [7:0]            current_level;     
output  [511:0]          word_out;
output  [0:0]            valid_out;

//output  [7:0]            counter_out;



wire  [31:0]    word_out_wire               [pipeline_no-1:0];
wire  [0:0]     valid_out_wire              [pipeline_no-1:0];
wire  [0:0]     word_in_valid_wire          [pipeline_no-1:0];
wire  [31:0]     word_in_th_wire            [pipeline_no-1:0];

wire  [31:0]    word_out_wire_sorted        [pipeline_no-1:0];
wire            valid_out_wire_sorted       [pipeline_no-1:0];

wire  [255:0]   word_out_wire_final;   
wire  [7:0]     valid_out_wire_final;    
//output  [7:0]     test_valid;

input  [0:0]    last_input_in;
output [0:0]    done;
//assign test_valid = {valid_out_wire[0], valid_out_wire[1], valid_out_wire[2], valid_out_wire[3], valid_out_wire[4], valid_out_wire[5], valid_out_wire[6], valid_out_wire[7]};

    
assign  word_out_wire_final    = {word_out_wire_sorted[7],    word_out_wire_sorted[6],   word_out_wire_sorted[5],    word_out_wire_sorted[4],  word_out_wire_sorted[3],    word_out_wire_sorted[2],   word_out_wire_sorted[1],    word_out_wire_sorted[0]};
assign  valid_out_wire_final   = {valid_out_wire_sorted[7],   valid_out_wire_sorted[6],  valid_out_wire_sorted[5],   valid_out_wire_sorted[4], valid_out_wire_sorted[3],   valid_out_wire_sorted[2],  valid_out_wire_sorted[1],   valid_out_wire_sorted[0]};

wire [32:0] sorter_input [pipeline_no-1:0];

assign sorter_input[0] = {word_out_wire[0], valid_out_wire[0]};
assign sorter_input[1] = {word_out_wire[1], valid_out_wire[1]};
assign sorter_input[2] = {word_out_wire[2], valid_out_wire[2]};
assign sorter_input[3] = {word_out_wire[3], valid_out_wire[3]};
assign sorter_input[4] = {word_out_wire[4], valid_out_wire[4]};
assign sorter_input[5] = {word_out_wire[5], valid_out_wire[5]};
assign sorter_input[6] = {word_out_wire[6], valid_out_wire[6]};
assign sorter_input[7] = {word_out_wire[7], valid_out_wire[7]};

wire [0:0] last_input_out_wire [pipeline_no-1:0];
wire [0:0] last_input_out_sorter;
wire [1:0] control_out_wire [pipeline_no-1:0];
wire [1:0] control_out_sorter;	
wire [0:0] word_in_valid_sorter;
wire [31:0] word_in_th_sorter;

	genvar numstg;
    generate
        for(numstg=0; numstg < pipeline_no; numstg = numstg+1)
        begin: elements
            bfs_pipeline #(.ADDR_W(ADDR_W), .stage_no(stage_no), .pipeline_id(numstg))
            pipe (              
                .clk(clk),
                .rst(rst),
                .last_input_in(last_input_in),
                .word_in(word_in),
				.word_in_valid(word_in_valid),
				.word_in_th(word_in_th),
                .control(control),
                .current_level(current_level),
                .last_input_out(last_input_out_wire[numstg]),
				.control_out(control_out_wire[numstg]),
                .word_out(word_out_wire[numstg]),
                .valid_out(valid_out_wire[numstg]),
				.word_in_valid_out(word_in_valid_wire[numstg]),
				.word_in_th_out(word_in_th_wire[numstg])				
            );         
        end
    endgenerate
   
    sort sorter(
       .clk(clk),
       .rst(rst),
       .last_input_in(last_input_out_wire[0]),
	   .control_in(control_out_wire[0]),
       .word_in_valid(word_in_valid_wire[0]),
	   .word_in_th(word_in_th_wire[0]),
	   .word_in0(sorter_input[0]),
       .word_in1(sorter_input[1]),
       .word_in2(sorter_input[2]),
       .word_in3(sorter_input[3]),
       .word_in4(sorter_input[4]),
       .word_in5(sorter_input[5]),
       .word_in6(sorter_input[6]),
       .word_in7(sorter_input[7]),
           
       .word_out0(word_out_wire_sorted[0]),
       .word_out1(word_out_wire_sorted[1]),
       .word_out2(word_out_wire_sorted[2]),
       .word_out3(word_out_wire_sorted[3]),
       .word_out4(word_out_wire_sorted[4]),
       .word_out5(word_out_wire_sorted[5]),
       .word_out6(word_out_wire_sorted[6]),
       .word_out7(word_out_wire_sorted[7]),
       
       .valid_out0(valid_out_wire_sorted[0]),
       .valid_out1(valid_out_wire_sorted[1]),
       .valid_out2(valid_out_wire_sorted[2]),
       .valid_out3(valid_out_wire_sorted[3]),
       .valid_out4(valid_out_wire_sorted[4]),
       .valid_out5(valid_out_wire_sorted[5]),
       .valid_out6(valid_out_wire_sorted[6]),
       .valid_out7(valid_out_wire_sorted[7]),
	   .control_out(control_out_sorter),
       .last_input_out(last_input_out_sorter),
	   .word_in_valid_out(word_in_valid_sorter),
	   .word_in_th_out(word_in_th_sorter)	
    );
   
    update_buffer    U_buff(
        .clk(clk),
        .rst(rst),
		.last_input_in(last_input_out_sorter),
		.control(control_out_sorter),
        .word_in(word_out_wire_final),
		.word_in_valid(word_in_valid_sorter),
		.word_in_th(word_in_th_sorter),			
        .valid_in(valid_out_wire_final),
        .done(done),
        .word_out(word_out),
        .valid_out(valid_out)
    );
   
   //assign word_out = {word_out_wire_final, valid_out_wire_final};
   //assign valid_out = (control == 2);
      
endmodule



