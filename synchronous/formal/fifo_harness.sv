`define HAS_PTRS
`timescale 1ns/1ps

module fifo_harness;

  parameter WIDTH = 8;
  parameter DEPTH = 16;
  localparam ADDR_WIDTH = $clog2(DEPTH);

  // nondeterministic inputs
  reg clk, rst_n, wr_en, rd_en;
  reg [WIDTH-1:0] wr_data;

  // outputs from DUT
  wire [WIDTH-1:0] rd_data;
  wire [$clog2(DEPTH):0] used;
  wire full, empty;

  // DUT
  fifo_sync #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
    .clk(clk), .rst_n(rst_n),
    .wr_en(wr_en), .wr_data(wr_data), .full(full),
    .rd_en(rd_en), .rd_data(rd_data),
    .empty(empty), .used(used)
  );

`ifdef FORMAL

// -------------------------
// 0. Reset behavior
// -------------------------
initial assume(!rst_n);              // start in reset
always @(posedge clk) cover(!rst_n); // encourage exploring reset

// after reset is released (1 cycle later)
always @(posedge clk)
  if (!$initstate && $past(!rst_n) && rst_n) begin
    assert(used == 0);
    assert(empty);
    assert(!full);
  end

// -------------------------
// 1. Correctness of used / flags
// -------------------------
always @(posedge clk)
  if (rst_n) begin
    assert(used <= DEPTH);
    assert(!full  || used == DEPTH);
    assert(!empty || used == 0);
    assert(!(full && empty));
    assert(used == $past(used)
        || used == $past(used)+1
        || used == $past(used)-1);
  end

// -------------------------
// 2. Pointer properties
// -------------------------
`ifdef HAS_PTRS

wire [ADDR_WIDTH:0] wptr = dut.w_ptr;
wire [ADDR_WIDTH:0] rptr = dut.r_ptr;

// pointer distance (wrap-aware)
wire [ADDR_WIDTH:0] addr_diff =
    (wptr >= rptr) ? (wptr - rptr) : (wptr + DEPTH - rptr);

// occupancy must match pointer distance
always @(posedge clk)
  if (!$initstate && $past(!rst_n) && rst_n)
    assert(used == addr_diff || (addr_diff == 0 && used == DEPTH));

// pointer stepping — only when reset inactive for 2 cycles
always @(posedge clk)
  if (!$initstate && $past(rst_n) && rst_n) begin
    assert(wptr == $past(wptr) || wptr == $past(wptr)+1);
    assert(rptr == $past(rptr) || rptr == $past(rptr)+1);
  end

`endif

// -------------------------
// 3. DATA INTEGRITY (shadow FIFO)
// -------------------------
reg [WIDTH-1:0] model_mem [0:DEPTH-1];
reg [ADDR_WIDTH-1:0] mw, mr;
reg [$clog2(DEPTH):0] mcount;
reg [WIDTH-1:0] exp_rd;

always @(posedge clk) begin
  if (!rst_n) begin
    mw <= 0; mr <= 0; mcount <= 0;
  end else begin
    exp_rd <= model_mem[mr];             // old data (read-before-write)

    if (rd_en && !empty)
      assert(rd_data == exp_rd);

    case ({wr_en && !full, rd_en && !empty})
      2'b10: begin
        model_mem[mw] <= wr_data;   mw <= mw + 1; mcount <= mcount + 1;
      end
      2'b01: begin
        mr <= mr + 1;               mcount <= mcount - 1;
      end
      2'b11: begin
        model_mem[mw] <= wr_data;   mw <= mw + 1;
        mr <= mr + 1;               mcount <= mcount;
      end
    endcase

    assert(mcount <= DEPTH);
  end
end

// -------------------------
// 4. Environment assumptions
// -------------------------
always @* begin
  assume(!(wr_en && full));   // producer is polite
  assume(!(rd_en && empty));  // consumer is polite
end

// -------------------------
// 5. Progress covers
// -------------------------
always @(posedge clk)
  if (rst_n) begin
    cover(used == DEPTH);
    cover(used == 0 && $past(used) != 0);
  end

`endif

endmodule

