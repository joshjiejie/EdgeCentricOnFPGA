//------------------------------------------------------------------------
// AFU user module 
//
// Copies content of src buffer onto destination buffer in memory
//------------------------------------------------------------------------


module afu_user #(ADDR_LMT = 20, MDATA = 14, CACHE_WIDTH = 512) 
(
   input                   clk,                
   input                   reset_n,                  
   
   // Read Request
   output [ADDR_LMT-1:0]   rd_req_addr,           
   output [MDATA-1:0] 	   rd_req_mdata,            
   output reg              rd_req_en,             
   input                   rd_req_almostfull,           
   
   // Read Response
   input                   rd_rsp_valid,       
   input [MDATA-1:0] 	   rd_rsp_mdata,            
   input [CACHE_WIDTH-1:0] rd_rsp_data,           

   // Write Request 
   output [ADDR_LMT-1:0]    wr_req_addr,           
   output [MDATA-1:0] 	    wr_req_mdata,            
   output reg [CACHE_WIDTH-1:0] wr_req_data,    
   output reg               wr_req_en,             
   input                    wr_req_almostfull,           
   
   // Write Response 
   input                    wr_rsp0_valid,       
   input [MDATA-1:0] 	    wr_rsp0_mdata,            
   input                    wr_rsp1_valid,       
   input [MDATA-1:0] 	    wr_rsp1_mdata,            
   
   // Start input signal
   input                    start,                

   // Done output signal 
   output reg               done,          

   // Control info from software
   input [511:0] 	    afu_context
);

   reg rd_addr_cnt_inc;
   reg rd_addr_cnt_clr;
   reg wr_addr_cnt_inc;
   reg wr_addr_cnt_clr;
   reg rd_rep_cnt_inc;
   reg rd_rep_cnt_clr;

   // --- This afu_user don't use mdata, just set to 0
   assign rd_req_mdata = 0;            
   assign wr_req_mdata = 0;            
 
   // --- Address counter 
   reg [31:0] rd_addr_cnt;
   reg [31:0] wr_addr_cnt;
   reg [31:0] rd_rep_cnt;
	  
   // --- Rd and Wr Addr
   assign rd_req_addr = rd_addr_cnt;           
   assign wr_req_addr = wr_addr_cnt;           


   // --- Num cache lines to copy (from AFU context)
   wire [31:0] num_clines;
   assign num_clines = afu_context[223:192];
   
   wire	[0:0]	sssp_done;	
   wire	[511:0]	sssp_word_out;	
   wire	[0:0]	sssp_valid_out;
   
   reg [0:0] last_input;
   reg [0:0] reset_afu;
   reg [0:0] run_afu; 	
   	
   always @ (posedge clk) begin
      if(!reset_n) begin 
		rd_addr_cnt <= 1'd0;
		wr_addr_cnt <= 1'd0;
		rd_rep_cnt  <= 1'd0;			
      end else begin
        if(rd_addr_cnt_inc) begin
			rd_addr_cnt <= rd_addr_cnt + 1;
		end else if(rd_addr_cnt_clr) begin
			rd_addr_cnt <= 1'd0;
		end else begin
			rd_addr_cnt <= rd_addr_cnt;
		end
		
		if(wr_addr_cnt_inc) begin
			wr_addr_cnt <= wr_addr_cnt + 1;
		end else if(wr_addr_cnt_clr) begin
			wr_addr_cnt <= 1'd0;
		end else begin
			wr_addr_cnt <= wr_addr_cnt;
		end		
		
		if(rd_rep_cnt_inc) begin
			rd_rep_cnt <= rd_rep_cnt + 1;
		end else if(rd_rep_cnt_clr) begin
			rd_rep_cnt <= 1'd0;
		end else begin
			rd_rep_cnt <= rd_rep_cnt;
		end		
		
	  end
   end
   
	
   
   
	   sssp #(.ADDR_W(12), .pipeline_no(8))
	   sssp_acc(
		.clk(clk),
		.rst(~reset_n | reset_afu),
		.last_input_in(last_input),
		.word_in(rd_rsp_data),
		.word_in_valid(rd_rsp_valid & run_afu),
		.control(afu_context[9:8]),
		.current_level(afu_context[7:0]),		
		.done(sssp_done),
		.word_out(sssp_word_out), 
		.valid_out(sssp_valid_out)		
	 );
 
   
   // --- FSM
   localparam [2:0]
     FSM_IDLE   		= 3'd0,
     FSM_RUN 			= 3'd4,
     FSM_WAIT_REQ	 	= 3'd6,
     FSM_DONE   		= 3'd7;
 
   reg [2:0]  fsm_cs, fsm_ns; 

  	
   always @ (posedge clk) begin
      if(!reset_n) fsm_cs <= FSM_IDLE;
      else         fsm_cs <= fsm_ns; 
   end


   always @ * begin
      fsm_ns = fsm_cs;
      rd_addr_cnt_inc = 1'b0;           
	  wr_addr_cnt_inc = 1'b0;
	  rd_rep_cnt_inc = 1'b0;	  
      rd_req_en = 1'b0;             
      wr_req_en = 1'b0;             
      done = 1'b0;          
	  last_input = 1'b0;
	  reset_afu = 1'b0; 
	  wr_req_data = 0;	
 	  wr_addr_cnt_clr = 1'b0;
      rd_addr_cnt_clr = 1'b0;
	  rd_rep_cnt_clr = 1'b0;
	  run_afu = 1'b1;	
	  
      case(fsm_cs)
         FSM_IDLE: begin
			rd_addr_cnt_clr = 1'b0;
			wr_addr_cnt_clr = 1'b0;
			rd_rep_cnt_clr = 1'b0;
			wr_req_data = 0;
			run_afu = 1'b0;
           if(start) begin
               fsm_ns = FSM_RUN;
               reset_afu = 1;
            end
         end
		 FSM_RUN: begin
			if((!rd_req_almostfull) & (!wr_req_almostfull)) begin
				if(rd_addr_cnt < num_clines) begin
				   rd_req_en = 1'b1;             	
				   rd_addr_cnt_inc = 1'b1;	
				end else begin
				   fsm_ns = FSM_WAIT_REQ;
				end												
			end
			if(rd_rsp_valid) begin
				rd_rep_cnt_inc = 1'b1;
			end		

			if(sssp_valid_out) begin				
				wr_req_data = sssp_word_out;
				wr_req_en = 1'b1;    // issue wr_req
				wr_addr_cnt_inc = 1'b1; // address counter ++
			end			
		 end
         
		
		FSM_WAIT_REQ: begin	
			if(sssp_done) begin
				fsm_ns = FSM_DONE;
			end 
			
			if(sssp_valid_out) begin							
				wr_req_data = sssp_word_out;
				wr_req_en = 1'b1;    // issue wr_req
				wr_addr_cnt_inc = 1'b1; // address counter ++
			end						
				 

			if(rd_rsp_valid) begin
				rd_rep_cnt_inc = 1'b1;
			end

			if(rd_rep_cnt == num_clines) begin
				last_input = 1'b1;
			end			
		end		
        
		FSM_DONE: begin
             done   = 1'b1;     
             reset_afu =  1'b1;			 
             wr_addr_cnt_clr = 1'b1;
             rd_addr_cnt_clr = 1'b1;
			 rd_rep_cnt_clr = 1'b1;
			 fsm_ns = FSM_IDLE;
			 run_afu = 1'b0;
          end
      endcase
   end

endmodule

