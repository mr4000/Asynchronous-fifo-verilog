`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.11.2025 11:54:43
// Design Name: 
// Module Name: synchronous_fifo
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


module fifo_sync #(
    parameter WIDTH = 8,        // bits per word
    parameter DEPTH = 16        // number of entries (prefer power-of-two)
) (
    input  wire                 clk,       // single clock
    input  wire                 rst_n,     // active-low synchronous reset

    // Write interface
    input  wire                 wr_en,     // write enable (valid)
    input  wire [WIDTH-1:0]     wr_data,   // write data
    output wire                 full,      // high when FIFO cannot accept more

    // Read interface
    input  wire                 rd_en,     // read enable (consumer ready)
    output reg  [WIDTH-1:0]     rd_data,   // read data (registered)
    output wire                 empty,     // high when FIFO is empty

    // Optional (observability)
    output wire [$clog2(DEPTH):0] used     // number of stored entries (optional)
);


  localparam ADDR_WIDTH = $clog2(DEPTH); // number of index bits

  // memory
  reg [WIDTH-1:0] mem [0:DEPTH-1];

  // pointers with extra MSB (wrap bit)
  reg [ADDR_WIDTH:0] w_ptr, r_ptr;

  // index wires for memory access (lower bits)
  wire [ADDR_WIDTH-1:0] w_index = w_ptr[ADDR_WIDTH-1:0];
  wire [ADDR_WIDTH-1:0] r_index = r_ptr[ADDR_WIDTH-1:0];




//method 1 full detection
//assign empty = (w_ptr == r_ptr);
//assign full  = ((w_ptr + 1) == r_ptr);

              
          
     //method 2 FULL DETECTION     
     
//    reg [$clog2(DEPTH):0] count;
    
//    assign full  = (count == DEPTH);
//    assign empty = (count == 0);
    
//    always @(posedge clk) begin
//        if (!rst_n) begin
//            count <= 0;
//        end else begin
//            case ({wr_en && !full, rd_en && !empty})
//                2'b10: count <= count + 1;   // write only
//                2'b01: count <= count - 1;   // read only
//                2'b11: count <= count;       // read & write cancel out
//            endcase
//        end
//    end

//Method 3
 
   // empty: exact pointer match (same lap, same index)
  assign empty = (w_ptr == r_ptr);

  // full: same index but MSB differs (writer lapped reader)
  assign full  = ( (w_ptr[ADDR_WIDTH] != r_ptr[ADDR_WIDTH]) &&
                    (w_ptr[ADDR_WIDTH-1:0] == r_ptr[ADDR_WIDTH-1:0]) );


// Used / occupancy (driven by a counter for observability)
  reg [$clog2(DEPTH):0] used_reg;
  assign used = used_reg;
  
  // single sequential block: reset pointers, mem accesses, used updates
  always @(posedge clk) begin
    if (!rst_n) begin
      w_ptr   <= { (ADDR_WIDTH+1){1'b0} };
      r_ptr   <= { (ADDR_WIDTH+1){1'b0} };
      rd_data <= {WIDTH{1'b0}};
      used_reg <= {($clog2(DEPTH)+1){1'b0}};
    end else begin
      // WRITE: only when write requested and not full
      if (wr_en && !full) begin
        mem[w_index] <= wr_data;
        w_ptr <= w_ptr + 1'b1;
      end

      // READ: only when read requested and not empty
      if (rd_en && !empty) begin
        rd_data <= mem[r_index];
        r_ptr <= r_ptr + 1'b1;
      end

      // used/occupancy update: write-only +1, read-only -1, both -> unchanged
      case ({(wr_en && !full), (rd_en && !empty)})
        2'b10: used_reg <= used_reg + 1;
        2'b01: used_reg <= used_reg - 1;
        default: used_reg <= used_reg; // 00 or 11 -> no change
      endcase
    end
  end
  
  
endmodule
