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
   

   // --- This afu_user don't use mdata, just set to 0
   assign rd_req_mdata = 0;            
   assign wr_req_mdata = 0;            
 
   // --- Address counter 
   reg [31:0] rd_addr_cnt;
   reg [31:0] wr_addr_cnt;
   
   // --- Rd and Wr Addr
   assign rd_req_addr = rd_addr_cnt;           
   assign wr_req_addr = wr_addr_cnt;           


   // --- Num cache lines to copy (from AFU context)
   wire [31:0] num_clines;
   assign num_clines = afu_context[223:192];
   
   wire	[0:0]	bfs_done;	
   wire	[511:0]	bfs_word_out;	
   wire	[0:0]	bfs_valid_out;
   
   reg [0:0] last_input;
   reg [0:0] reset_afu;
   reg [0:0]	bfs_valid_out_buff;
   reg [511:0]	bfs_word_out_buff;
   reg [0:0]	clk_en;	
   reg [0:0]  already_start;
   	
   always @ (posedge clk) begin
      if(!reset_n) begin 
		rd_addr_cnt <= 0;
		wr_addr_cnt <= 0;		
		bfs_valid_out_buff <=0;
		bfs_word_out_buff <=0;
		already_start <=0;
      end else begin
      	bfs_valid_out_buff <= bfs_valid_out;
		bfs_word_out_buff  <= bfs_word_out;
		if(start) begin 
			already_start <=1;  
		end else begin 
			already_start <=already_start; 
		end
        if(rd_addr_cnt_inc) 
			rd_addr_cnt <= rd_addr_cnt + 1;
		else if(rd_addr_cnt_clr)
			rd_addr_cnt <= 'd0;
		
		if(wr_addr_cnt_inc) 
			wr_addr_cnt <= wr_addr_cnt + 1;
		else if(wr_addr_cnt_clr)
			wr_addr_cnt <= 'd0;
			
	  end
   end
   
	
   
   
	   bfs #(.ADDR_W(4), .stage_no(3), .pipeline_no(8))
	   bfs_acc(
		.clk(clk & clk_en),
		.rst(~reset_n | reset_afu),
		.last_input_in(last_input),
		.word_in(rd_rsp_data),
		.word_in_valid(rd_rsp_valid),
		.word_in_th(rd_addr_cnt),
		.control(afu_context[9:8]),
		.current_level(afu_context[7:0]),		
		.done(bfs_done),
		.word_out(bfs_word_out), 
		.valid_out(bfs_valid_out)		
	 );
 
   
   // --- FSM
   localparam [2:0]
     FSM_IDLE   		= 3'd0,
     FSM_RD_REQ 		= 3'd1,
     FSM_RD_RSP 		= 3'd2,
     FSM_WR_REQ 		= 3'd3,
     FSM_WR_RSP 		= 3'd5,
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
      rd_req_en = 1'b0;             
      wr_req_en = 1'b0;             
      done = 1'b0;          
	  last_input = 1'b0;
	  clk_en = 1'b0;
	  reset_afu = 0;
 	  
      case(fsm_cs)
         FSM_IDLE: begin
			clk_en = 1'b0;
			rd_addr_cnt_clr = 1'b0;
			wr_addr_cnt_clr = 1'b0;
            if(start) begin
               fsm_ns = FSM_RD_REQ;
               clk_en = 1'b1;
               reset_afu = 1;
            end
         end
         FSM_RD_REQ: begin
			clk_en = 1'b0;
		    if(!rd_req_almostfull) begin           
			   rd_req_en = 1'b1;             
			   fsm_ns = FSM_RD_RSP;	
			   rd_addr_cnt_inc = 1'b1;		
		    end 
         end
         FSM_RD_RSP: begin 
			clk_en = 1'b0;
			if(rd_rsp_valid) begin
				clk_en = 1;											
				if(rd_addr_cnt >= num_clines) begin 
					fsm_ns = FSM_WAIT_REQ;	
					last_input = 1'b1;	
				end else begin
					if(bfs_valid_out) begin				
						fsm_ns = FSM_WR_REQ;					
					end else begin
						fsm_ns = FSM_RD_REQ;
					end					
				end				
			end
		end
	
        FSM_WR_REQ: begin	
			clk_en = 1'b0;
			if(!wr_req_almostfull) begin				
				wr_req_en = 1'b1;    // issue wr_req
				wr_addr_cnt_inc = 1'b1; // address counter ++
				wr_req_data = bfs_word_out;			
				fsm_ns = FSM_WR_RSP; 
            end 
        end
		FSM_WR_RSP: begin
			clk_en = 1'b0;
			if(wr_rsp0_valid | wr_rsp1_valid) begin												
				//clk_en = 1;
				if(rd_addr_cnt >= num_clines) begin
					fsm_ns = FSM_WAIT_REQ; 
				end else begin
					if(bfs_valid_out) begin				
						fsm_ns = FSM_WR_REQ;										
					end else begin
						fsm_ns = FSM_RD_REQ; 
					end	
				end
			end 
		end
		
		FSM_WAIT_REQ: begin	
			clk_en = 1'b1;
			if(bfs_done) begin
				fsm_ns = FSM_DONE;
			end else begin
				if(bfs_valid_out) begin							
					fsm_ns = FSM_WR_REQ;	
				end						
			end	            
		end		
        
		FSM_DONE: begin
             done   = 1'b1;     // assert done signal 
             reset_afu =  1'b1;
			 clk_en = 0;
			 already_start = 0;
			 fsm_ns = FSM_IDLE; // stay in this state
             wr_addr_cnt_clr = 1'b1;
             rd_addr_cnt_clr = 1'b1;
          end
      endcase
   end

endmodule

