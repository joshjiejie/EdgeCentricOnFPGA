`timescale 1ns / 1ps

module sssp(
    clk,
    rst,    
    last_input_in,
    word_in,
	word_in_valid,
    control,
    current_level,
    done,
    word_out, 
    valid_out
    //test_valid,
    //counter_out
 );

parameter ADDR_W = 12;               // this value decides how many vertices in a BRAM  
//total number of vertices stored on-chip: 2^ADDR * 2^stage_no
parameter pipeline_no = 8;

input   clk, rst;
input   [511:0]              word_in;
input   [1:0]               control;
input	[0:0]	word_in_valid;


input   [7:0]            current_level;     
output  reg [511:0]          word_out;
output  reg [0:0]            valid_out;

//output  [7:0]            counter_out;



wire  [63:0]    word_out_wire               [pipeline_no-1:0];
wire  [0:0]     valid_out_wire              [pipeline_no-1:0];
wire  [0:0]     word_in_valid_wire          [pipeline_no-1:0];

wire  [63:0]    word_out_wire_sorted        [pipeline_no-1:0];
wire            valid_out_wire_sorted       [pipeline_no-1:0];

wire  [511:0]   word_out_wire_final;   
wire  [7:0]     valid_out_wire_final;    
//output  [7:0]     test_valid;

input  [0:0]    last_input_in;
//output [0:0]    done;
output reg [0:0]    done;
reg [0:0]    done_buff;
//assign test_valid = {valid_out_wire[0], valid_out_wire[1], valid_out_wire[2], valid_out_wire[3], valid_out_wire[4], valid_out_wire[5], valid_out_wire[6], valid_out_wire[7]};


reg [31:0]	counter;


assign  word_out_wire_final    = {word_out_wire_sorted[7],    word_out_wire_sorted[6],   word_out_wire_sorted[5],    word_out_wire_sorted[4],  word_out_wire_sorted[3],    word_out_wire_sorted[2],   word_out_wire_sorted[1],    word_out_wire_sorted[0]};
assign  valid_out_wire_final   = {valid_out_wire_sorted[7],   valid_out_wire_sorted[6],  valid_out_wire_sorted[5],   valid_out_wire_sorted[4], valid_out_wire_sorted[3],   valid_out_wire_sorted[2],  valid_out_wire_sorted[1],   valid_out_wire_sorted[0]};

//assign  word_out_wire_final    = {word_out_wire[7],    word_out_wire[6],   word_out_wire[5],    word_out_wire[4],  word_out_wire[3],    word_out_wire[2],   word_out_wire[1],    word_out_wire[0]};
//assign  valid_out_wire_final   = {valid_out_wire[7],   valid_out_wire[6],  valid_out_wire[5],   valid_out_wire[4], valid_out_wire[3],   valid_out_wire[2],  valid_out_wire[1],   valid_out_wire[0]};

wire [64:0] sorter_input [pipeline_no-1:0];

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

reg     [63:0]    update_buff [6:0];
integer i;
	
	genvar numstg;
    generate
        for(numstg=0; numstg < pipeline_no; numstg = numstg+1)
        begin: elements
            sssp_pipeline #(.ADDR_W(ADDR_W), .pipeline_id(numstg))
            pipe (              
                .clk(clk),
                .rst(rst),
                .last_input_in(last_input_in),
                .word_in(word_in),
				.word_in_valid(word_in_valid),
                .control(control),
                .current_level(current_level),
                .last_input_out(last_input_out_wire[numstg]),
				.control_out(control_out_wire[numstg]),
                .word_out(word_out_wire[numstg]),
                .valid_out(valid_out_wire[numstg]),
				.word_in_valid_out(word_in_valid_wire[numstg])				
            );         
        end
    endgenerate

    sort sorter(
       .clk(clk),
       .rst(rst),
       .last_input_in(last_input_out_wire[0]),
	   .control_in(control_out_wire[0]),
       .word_in_valid(word_in_valid_wire[0]),
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
	   .word_in_valid_out(word_in_valid_sorter)
    );
 

	always @ (posedge clk) begin
      	if (rst) begin
      			done <= 1'b0;
      			done_buff <= 1'b0;;
				counter <=0;
				word_out <=0;
				valid_out <=1'b0;;
				for(i=0; i<7; i=i+1) begin 
					update_buff [i] <=0;            
				end
      	end else begin
			done <= done_buff;
			counter <= counter;
			done_buff <= done_buff;			
			for(i=0; i<7; i=i+1) begin 
                update_buff [i] <= update_buff [i] ;            
            end
			word_out  <= 0;
			valid_out <= 1'b0;
			if(last_input_out_sorter) begin
				done_buff <=1;	
				valid_out <=(counter>0);
				word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4],update_buff[5],update_buff[6], 64'h000000000000000};	
				counter <= 0;
			end else begin								
				case(valid_out_wire_final)					
					8'b10000000: begin                    
						if(counter<7) begin
						   counter <= counter +1;
						   update_buff[counter] <= word_out_wire_final[511:448]; 
						   valid_out <= 1'b0;
						end else begin
						   counter <= 0;
						   valid_out <=1'b1;
						   word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4],update_buff[5],update_buff[6], word_out_wire_final[511:448]}; 
						end                        
					end
					8'b11000000: begin                    
					   if(counter<6) begin
						  counter <= counter +2;
						  valid_out <= 1'b0;
						  update_buff[counter]   <= word_out_wire_final[511:448]; 
						  update_buff[counter+1] <= word_out_wire_final[447:384]; 
					   end else if (counter==6) begin
						  counter <= 0;
						  valid_out <=1'b1;
						  word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4],update_buff[5], word_out_wire_final[511:384]};                                                                       
					   end else begin
						  counter <= 1;
						  valid_out <=1'b1;
						  word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4],update_buff[5],update_buff[6], word_out_wire_final[511:448]}; 
						  update_buff[0] <= word_out_wire_final[447:384];       
					   end                       
				   end
				   8'b11100000: begin                    
					  if(counter<5) begin
						 counter <= counter +3;
						 valid_out <= 1'b0;
						 update_buff[counter]   <= word_out_wire_final[511:448]; 
						 update_buff[counter+1] <= word_out_wire_final[447:384]; 
						 update_buff[counter+2] <= word_out_wire_final[383:320]; 
					  end else if (counter==5) begin
						 counter <= 0;
						 valid_out <=1'b1;
						 word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4], word_out_wire_final[511:320]};                                                                  
					  end else if (counter==6) begin
						 counter <= 1;
						 valid_out <= 1'b1;
						 word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4],update_buff[5], word_out_wire_final[511:384]};
						 update_buff[0] <= word_out_wire_final[383:320];                             
					  end else begin
						 counter <= 2;
						 valid_out <=1'b1;
						 word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4],update_buff[5],update_buff[6], word_out_wire_final[511:448]};
						 update_buff[0] <= word_out_wire_final[447:384]; 
						 update_buff[1] <= word_out_wire_final[383:320]; 
					  end                                        
				   end
				   8'b11110000: begin                    
						 if(counter<4) begin
							counter <= counter +4;
							valid_out <= 1'b0;
							update_buff[counter]   <= word_out_wire_final[511:448]; 
							update_buff[counter+1] <= word_out_wire_final[447:384]; 
							update_buff[counter+2] <= word_out_wire_final[383:320]; 
							update_buff[counter+3] <= word_out_wire_final[319:256];
						 end else if (counter==4) begin
							counter <= 0;
							valid_out <=1'b1;
							word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3], word_out_wire_final[511:256]};                                                                       
						 end else if (counter==5) begin
							counter <= 1;
							valid_out <=1'b1;
							word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4],word_out_wire_final[511:320]}; 
							update_buff[0] <= word_out_wire_final[319:256];                                
						 end else if (counter==6) begin
							 counter <= 2;
							 valid_out <=1'b1;
							 word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4],update_buff[5],word_out_wire_final[511:384]};
							 update_buff[0] <= word_out_wire_final[383:320]; 
							 update_buff[1] <= word_out_wire_final[319:256];                   
						 end else begin
							counter <= 3;
							valid_out <=1'b1;
							word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4],update_buff[5],update_buff[6],word_out_wire_final[511:448]};
							update_buff[0] <= word_out_wire_final[447:384]; 
							update_buff[1] <= word_out_wire_final[383:320];  
							update_buff[2] <= word_out_wire_final[319:256];
						 end                                        
				   end
				   8'b11111000: begin                    
						if(counter<3) begin
						   counter <= counter+5;
						   valid_out <= 1'b0;
						   update_buff[counter]   <= word_out_wire_final[511:448]; 
						   update_buff[counter+1] <= word_out_wire_final[447:384];
						   update_buff[counter+2] <= word_out_wire_final[383:320];
						   update_buff[counter+3] <= word_out_wire_final[319:256];
						   update_buff[counter+4] <= word_out_wire_final[255:192];
						end else if (counter==3) begin
						   counter <= 0;
						   valid_out <=1'b1;
						   word_out <= {update_buff[0],update_buff[1],update_buff[2],word_out_wire_final[511:192]};                                                                       
						end else if (counter==4) begin
						   counter <= 1;
						   valid_out <=1'b1;
						   word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3], word_out_wire_final[511:256]}; 
						   update_buff[0] <= word_out_wire_final[255:192];                                
						end else if (counter==5) begin
							counter <= 2;
							valid_out <=1'b1;
							word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4], word_out_wire_final[511:320]};
							update_buff[0] <= word_out_wire_final[319:256];
							update_buff[1] <= word_out_wire_final[255:192];           
						end else if (counter==6) begin
							counter   <= 3;
							valid_out <=1'b1;
							word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4],update_buff[5], word_out_wire_final[511:384]};
							update_buff[0] <= word_out_wire_final[383:320];
							update_buff[1] <= word_out_wire_final[319:256];
							update_buff[2] <= word_out_wire_final[255:192];
						end else begin
						   counter <= 4;
						   valid_out <=1'b1;
						   word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4],update_buff[5],update_buff[6],word_out_wire_final[511:448]};
						   update_buff[0] <= word_out_wire_final[447:384];
						   update_buff[1] <= word_out_wire_final[383:320];
						   update_buff[2] <= word_out_wire_final[319:256];
						   update_buff[3] <= word_out_wire_final[255:192];
						end                                        
					end
					8'b11111100: begin                    
						if(counter<2) begin
						   counter <= counter+6;
						   valid_out <= 1'b0;
						   update_buff[counter]   <= word_out_wire_final[511:448]; 
						   update_buff[counter+1] <= word_out_wire_final[447:384];
						   update_buff[counter+2] <= word_out_wire_final[383:320];
						   update_buff[counter+3] <= word_out_wire_final[319:256];
						   update_buff[counter+4] <= word_out_wire_final[255:192];
						   update_buff[counter+5] <= word_out_wire_final[191:128];
						end else if (counter==2) begin
						   counter <= 0;
						   valid_out <=1'b1;
						   word_out <= {update_buff[0],update_buff[1], word_out_wire_final[511:128]};                                                                       
						end else if (counter==3) begin
						   counter <= 1;
						   valid_out <=1'b1;
						   word_out <= {update_buff[0],update_buff[1],update_buff[2], word_out_wire_final[511:192]}; 
						   update_buff[0] <= word_out_wire_final[191:128];                                
						end else if (counter==4) begin
							counter <= 2;
							valid_out <=1'b1;
							word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3], word_out_wire_final[511:256]};
							update_buff[0] <= word_out_wire_final[255:192];
							update_buff[1] <= word_out_wire_final[191:128];                                             
						end else if (counter==5) begin
							counter   <= 3;
							valid_out <=1'b1;
							word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4], word_out_wire_final[511:320]};
							update_buff[0] <= word_out_wire_final[319:256];
							update_buff[1] <= word_out_wire_final[255:192];
							update_buff[2] <= word_out_wire_final[191:128];
						end else if (counter==6) begin
						   counter <= 4;
						   valid_out <=1'b1;
						   word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4],update_buff[5], word_out_wire_final[511:384]};                           
						   update_buff[0] <= word_out_wire_final[383:320];
						   update_buff[1] <= word_out_wire_final[319:256];
						   update_buff[2] <= word_out_wire_final[255:192];   
						   update_buff[3] <= word_out_wire_final[191:128];
						end else begin
						   counter <= 5;
						   valid_out <=1'b1;
						   word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4],update_buff[5],update_buff[6],word_out_wire_final[511:448]};
						   update_buff[0] <= word_out_wire_final[447:384];
						   update_buff[1] <= word_out_wire_final[383:320];
						   update_buff[2] <= word_out_wire_final[319:256];
						   update_buff[3] <= word_out_wire_final[255:192];  
						   update_buff[4] <= word_out_wire_final[191:128];
						end                                        
					end
					8'b11111110: begin                    
						if(counter<1) begin
						   counter <= counter+7;
						   valid_out <= 1'b0;
						   update_buff[counter]   <= word_out_wire_final[511:448]; 
						   update_buff[counter+1] <= word_out_wire_final[447:384];
						   update_buff[counter+2] <= word_out_wire_final[383:320];
						   update_buff[counter+3] <= word_out_wire_final[319:256];
						   update_buff[counter+4] <= word_out_wire_final[255:192];
						   update_buff[counter+5] <= word_out_wire_final[191:128];
						   update_buff[counter+6] <= word_out_wire_final[127:64];
						end else if (counter==1) begin
						   counter <= 0;
						   valid_out <=1'b1;
						   word_out <= {update_buff[0], word_out_wire_final[511:64]};                                                                       
						end else if (counter==2) begin
						   counter <= 1;
						   valid_out <=1'b1;
						   word_out <= {update_buff[0],update_buff[1], word_out_wire_final[511:128]}; 
						   update_buff[0] <= word_out_wire_final[127:64];                        
						end else if (counter==3) begin
							counter <= 2;
							valid_out <=1'b1;
							word_out <= {update_buff[0],update_buff[1],update_buff[2],word_out_wire_final[511:192]};
							update_buff[0] <= word_out_wire_final[191:128];
							update_buff[1] <= word_out_wire_final[127:64];                                          
						end else if (counter==4) begin
							counter   <= 3;
							valid_out <=1'b1;
							word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3], word_out_wire_final[511:256]};
							update_buff[0] <= word_out_wire_final[255:192];
							update_buff[1] <= word_out_wire_final[191:128];
							update_buff[2] <= word_out_wire_final[127:64];                       
						end else if (counter==5) begin
						   counter <= 4;
						   valid_out <=1'b1;
						   word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4], word_out_wire_final[511:320]};                           
						   update_buff[0] <= word_out_wire_final[319:256];
						   update_buff[1] <= word_out_wire_final[255:192];
						   update_buff[2] <= word_out_wire_final[191:128];
						   update_buff[3] <= word_out_wire_final[127:64];       
						end else if (counter==6) begin
							  counter <= 5;
							  valid_out <=1'b1;
							  word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4],update_buff[5], word_out_wire_final[511:384]};                           
							  update_buff[0] <= word_out_wire_final[383:320];
							  update_buff[1] <= word_out_wire_final[319:256];
							  update_buff[2] <= word_out_wire_final[255:192];
							  update_buff[3] <= word_out_wire_final[191:128];
							  update_buff[4] <= word_out_wire_final[127:64];          
						end else begin
						   counter <= 7;
						   valid_out <=1'b1;
						   word_out <= {update_buff[0],update_buff[1],update_buff[2],update_buff[3],update_buff[4],update_buff[5],update_buff[6],word_out_wire_final[511:448]};
						   update_buff[0] <= word_out_wire_final[447:384];
						   update_buff[1] <= word_out_wire_final[383:320];
						   update_buff[2] <= word_out_wire_final[319:256];
						   update_buff[3] <= word_out_wire_final[255:192];
						   update_buff[4] <= word_out_wire_final[191:128];
						   update_buff[5] <= word_out_wire_final[127:64];     
					   end                                        
					end
					8'b11111111: begin                    											   
						valid_out <=1'b1;
						word_out <= word_out_wire_final;					                                          
					end
					default: begin
						valid_out <= 1'b0;							
					end		
				endcase	
			end  
      	end         
    end
  
endmodule