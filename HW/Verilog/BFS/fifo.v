module fifo(
   // Outputs
   dout, full, empty, /*water_level,*/
   // Inputs
   clk, rst, r, w, din
   );

   parameter DATA_WIDTH = 32;
   parameter ADDR_WIDTH = 3;
   
   input     clk;
   input     rst;
   
   input     r;
   input     w;

   wire [(DATA_WIDTH-1):0] dout2;
   output [(DATA_WIDTH-1):0] dout;
   input [(DATA_WIDTH-1):0]  din;

   output 		     full;
   output 		     empty;
   
   reg [ADDR_WIDTH:0] 	     w_ptr, r_ptr;
   wire 		     r_mem, w_mem;

   assign dout = empty ? {(DATA_WIDTH-1){1'b0}} : dout2;
   assign full = (w_ptr[(ADDR_WIDTH-1):0] == r_ptr[(ADDR_WIDTH-1):0]) 
   && (w_ptr[ADDR_WIDTH] != r_ptr[ADDR_WIDTH]);
   
   assign 		     empty = (w_ptr == r_ptr);

   assign r_mem = (r && !empty) || (r && w);
   assign w_mem = (w && !full) || (r && w);

   
   //wire [ADDR_WIDTH:0] 	     w_water_level = (w_ptr - r_ptr);
      
   always@(posedge clk)
     begin
	if(rst)
	  begin
	     w_ptr <= 'd0;
	     r_ptr <= 'd0;
	  end
	else
	  begin
	     w_ptr <= (w && !full) ? w_ptr + 1 : w_ptr;
	     r_ptr <= (r && !empty) ? r_ptr + 1 : r_ptr;
	  end
     end

     
   fifo_storage #(DATA_WIDTH,ADDR_WIDTH ) m0
   (
	   // Outputs
	   .r_data			(dout2),
	   // Inputs
	   .clk				(clk),
	   .r_addr			(r_ptr[(ADDR_WIDTH-1):0]),
	   .w_addr			(w_ptr[(ADDR_WIDTH-1):0]),
	   .w_data			(din),
//	   .r				(r_mem),
	   .w				(w_mem)
    );
   

endmodule // fifo 

module fifo_storage(
   // Outputs
   r_data,
   // Inputs
   clk, r_addr, w_addr, w_data,/* r,*/ w
   );

   parameter DATA_WIDTH = 32;
   parameter ADDR_WIDTH = 3;
   parameter RAM_DEPTH = 1 << ADDR_WIDTH;
   
   input clk;
   input [(ADDR_WIDTH-1):0] r_addr;
   input [(ADDR_WIDTH-1):0] w_addr;

   input [(DATA_WIDTH-1):0] w_data;
   output[(DATA_WIDTH-1):0] r_data;

   //reg [(DATA_WIDTH-1):0] r_data;
   
   
   //input 		    r;
   input w;

   reg [(DATA_WIDTH-1):0] mem [(RAM_DEPTH-1):0];

   assign 		  r_data = mem[r_addr];
   always@(posedge clk)
     begin
	mem[w_addr] <= w ? w_data : mem[w_addr];
	//r_data <= r ? mem[r_addr] : r_data;
     end

endmodule // mem
		  
