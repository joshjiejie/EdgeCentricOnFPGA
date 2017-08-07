`timescale 1ns / 1ps

module sort(
    clk,
    rst,
    last_input_in,
	control_in,
	word_in_valid,
    word_in_th,
    word_in0,
    word_in1,
    word_in2,
    word_in3,
    word_in4,
    word_in5,
    word_in6,
    word_in7,
 
    
    word_out0,
    word_out1,
    word_out2,
    word_out3,
    word_out4,
    word_out5,
    word_out6,
    word_out7,
    
    valid_out0,
    valid_out1,
    valid_out2,
    valid_out3,
    valid_out4,
    valid_out5,
    valid_out6,
    valid_out7,
	control_out,
	last_input_out,
    word_in_valid_out,
    word_in_th_out
);

input clk, rst;
input [32:0]  word_in0,       word_in1,       word_in2,       word_in3,   word_in4,       word_in5,      word_in6,       word_in7;     
input [0:0]	last_input_in;
input [1:0] control_in;
input [0:0]		word_in_valid;
input [31:0]	word_in_th;

output reg [1:0] control_out;

output reg [0:0] last_input_out;
output reg [31:0]   word_out0,       word_out1,       word_out2,       word_out3,   word_out4,       word_out5,      word_out6,        word_out7;
output reg [0:0]    valid_out0,      valid_out1,      valid_out2,      valid_out3,  valid_out4,      valid_out5,     valid_out6,       valid_out7; 
output  reg [0:0]		word_in_valid_out;  // from afu-io
output  reg [31:0]		word_in_th_out;     // from afu-core

integer i, j;

reg [32:0] stage0 [7:0];
reg [32:0] stage1 [7:0];
reg [32:0] stage2 [7:0];
reg [32:0] stage3 [7:0];
reg [32:0] stage4 [7:0];
reg [0:0]  last_input_buff [4:0];
reg [1:0]  control_buff [4:0];
reg [0:0] word_in_valid_buff [4:0];
reg [0:0] word_in_th_buff [4:0];

always @(posedge clk) begin
        if(rst==1) begin
           for (i=0; i<8; i=i+1) begin
                stage0[i] <= 0;      
                stage1[i] <= 0; 
                stage2[i] <= 0; 
                stage3[i] <= 0;
                stage4[i] <= 0;
           end 	
		   for (j=0; j<5; j=j+1) begin
                last_input_buff [j] <=0;
				control_buff[j] <=0;
				word_in_valid_buff [j] <=0;
				word_in_th_buff [j] <=0;
           end  			 		
		end else begin
            stage0[0] <= (word_in0[0]<word_in1[0])?word_in0:word_in1;
            stage0[1] <= (word_in0[0]<word_in1[0])?word_in1:word_in0;
            stage0[2] <= (word_in2[0]<word_in3[0])?word_in2:word_in3;
            stage0[3] <= (word_in2[0]<word_in3[0])?word_in3:word_in2;
            stage0[4] <= (word_in4[0]<word_in5[0])?word_in4:word_in5;
            stage0[5] <= (word_in4[0]<word_in5[0])?word_in5:word_in4;
            stage0[6] <= (word_in6[0]<word_in7[0])?word_in6:word_in7;
            stage0[7] <= (word_in6[0]<word_in7[0])?word_in7:word_in6;
            last_input_buff [0] <= last_input_in;
			control_buff [0] 	<= control_in;
			word_in_valid_buff [0] <= word_in_valid;
			word_in_th_buff [0] 	<= word_in_th;
            
			//*******************************************************//
            stage1[0] <= (stage0[0][0]< stage0[3][0])?stage0[0]:stage0[3];
            stage1[3] <= (stage0[0][0]< stage0[3][0])?stage0[3]:stage0[0];
            stage1[1] <= (stage0[1][0]< stage0[2][0])?stage0[1]:stage0[2];
            stage1[2] <= (stage0[1][0]< stage0[2][0])?stage0[2]:stage0[1];
            stage1[4] <= (stage0[4][0]< stage0[7][0])?stage0[4]:stage0[7];
            stage1[7] <= (stage0[4][0]< stage0[7][0])?stage0[7]:stage0[4];
            stage1[5] <= (stage0[5][0]< stage0[6][0])?stage0[5]:stage0[6];
            stage1[6] <= (stage0[5][0]< stage0[6][0])?stage0[6]:stage0[5];
            last_input_buff [1] <= last_input_buff [0];
			control_buff [1] 	<= control_buff [0];
			word_in_valid_buff [1] <= word_in_valid_buff [0];
			word_in_th_buff [1] 	<= word_in_th_buff [0];
			
            //*******************************************************//
            stage2[0] <= (stage1[0][0]< stage1[1][0])?stage1[0]:stage1[1];
            stage2[1] <= (stage1[0][0]< stage1[1][0])?stage1[1]:stage1[0];
            stage2[2] <= (stage1[2][0]< stage1[3][0])?stage1[2]:stage1[3];
            stage2[3] <= (stage1[2][0]< stage1[3][0])?stage1[3]:stage1[2];
            stage2[4] <= (stage1[4][0]< stage1[5][0])?stage1[4]:stage1[5];
            stage2[5] <= (stage1[4][0]< stage1[5][0])?stage1[5]:stage1[4];
            stage2[6] <= (stage1[6][0]< stage1[7][0])?stage1[6]:stage1[7];
            stage2[7] <= (stage1[6][0]< stage1[7][0])?stage1[7]:stage1[6]; 
            last_input_buff [2] <= last_input_buff [1];
			control_buff [2] 	<= control_buff [1];
			word_in_valid_buff [2] <= word_in_valid_buff [1];
			word_in_th_buff [2] 	<= word_in_th_buff [1];
			
            //*******************************************************//
            stage3[0] <= (stage2[0][0]< stage2[7][0])?stage2[0]:stage2[7];
            stage3[7] <= (stage2[0][0]< stage2[7][0])?stage2[7]:stage2[0];
            stage3[1] <= (stage2[1][0]< stage2[6][0])?stage2[1]:stage2[6];
            stage3[6] <= (stage2[1][0]< stage2[6][0])?stage2[6]:stage2[1];
            stage3[2] <= (stage2[2][0]< stage2[5][0])?stage2[2]:stage2[5];
            stage3[5] <= (stage2[2][0]< stage2[5][0])?stage2[5]:stage2[2];
            stage3[3] <= (stage2[3][0]< stage2[4][0])?stage2[3]:stage2[4];
            stage3[4] <= (stage2[3][0]< stage2[4][0])?stage2[4]:stage2[3]; 
            last_input_buff [3] <= last_input_buff [2];
			control_buff [3] 	<= control_buff [2];
			word_in_valid_buff [3] <= word_in_valid_buff [2];
			word_in_th_buff [3] 	<= word_in_th_buff [2];
			
            //*******************************************************//
            stage4[0] <= (stage3[0][0]< stage3[2][0])?stage3[0]:stage3[2];
            stage4[2] <= (stage3[0][0]< stage3[2][0])?stage3[2]:stage3[0];
            stage4[1] <= (stage3[1][0]< stage3[3][0])?stage3[1]:stage3[3];
            stage4[3] <= (stage3[1][0]< stage3[3][0])?stage3[3]:stage3[1];
            stage4[4] <= (stage3[4][0]< stage3[6][0])?stage3[4]:stage3[6];
            stage4[6] <= (stage3[4][0]< stage3[6][0])?stage3[6]:stage3[4];
            stage4[5] <= (stage3[5][0]< stage3[7][0])?stage3[5]:stage3[7];
            stage4[7] <= (stage3[5][0]< stage3[7][0])?stage3[7]:stage3[5];
            last_input_buff [4] <= last_input_buff [3];
			control_buff [4] 	<= control_buff [3];
			word_in_valid_buff [4] <= word_in_valid_buff [3];
			word_in_th_buff [4] 	<= word_in_th_buff [3];
			
            //*******************************************************//
            word_out0 <= (stage4[0][0]< stage4[1][0])?stage4[0][32:1]:stage4[1][32:1];
            word_out1 <= (stage4[0][0]< stage4[1][0])?stage4[1][32:1]:stage4[0][32:1]; 
            word_out2 <= (stage4[2][0]< stage4[3][0])?stage4[2][32:1]:stage4[3][32:1];
            word_out3 <= (stage4[2][0]< stage4[3][0])?stage4[3][32:1]:stage4[2][32:1];
            word_out4 <= (stage4[4][0]< stage4[5][0])?stage4[4][32:1]:stage4[5][32:1];
            word_out5 <= (stage4[4][0]< stage4[5][0])?stage4[5][32:1]:stage4[4][32:1];
            word_out6 <= (stage4[6][0]< stage4[7][0])?stage4[6][32:1]:stage4[7][32:1];
            word_out7 <= (stage4[6][0]< stage4[7][0])?stage4[7][32:1]:stage4[6][32:1];
            
         
            valid_out0<= (stage4[0][0]< stage4[1][0])?stage4[0][0]:stage4[1][0];    
            valid_out1<= (stage4[0][0]< stage4[1][0])?stage4[1][0]:stage4[0][0]; 
            valid_out2<= (stage4[2][0]< stage4[3][0])?stage4[2][0]:stage4[3][0];
            valid_out3<= (stage4[2][0]< stage4[3][0])?stage4[3][0]:stage4[2][0];
            valid_out4<= (stage4[4][0]< stage4[5][0])?stage4[4][0]:stage4[5][0];
            valid_out5<= (stage4[4][0]< stage4[5][0])?stage4[5][0]:stage4[4][0];
            valid_out6<= (stage4[6][0]< stage4[7][0])?stage4[6][0]:stage4[7][0];
            valid_out7<= (stage4[6][0]< stage4[7][0])?stage4[7][0]:stage4[6][0];     
			
			last_input_out  	<= last_input_buff [4];
			control_out 		<= control_buff [4];
			word_in_valid_out 	<= word_in_valid_buff [4];
			word_in_th_out 		<= word_in_th_buff [4];
        end                
end           
endmodule
