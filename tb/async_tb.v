`timescale 1ns/1ps

module tb_async_fifo_simple;

  localparam WIDTH = 8;
  localparam DEPTH = 16;

  // DUT signals
  reg                 wr_clk, wr_rst_n;
  reg                 rd_clk, rd_rst_n;
  reg                 wr_en;
  reg  [WIDTH-1:0]    wr_data;
  wire                full;

  reg                 rd_en;
  wire [WIDTH-1:0]    rd_data;
  wire                empty;

  // DUT
  fifo_async #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
  ) dut (
    .wr_clk  (wr_clk),
    .wr_rst_n(wr_rst_n),
    .wr_en   (wr_en),
    .wr_data (wr_data),
    .full    (full),

    .rd_clk  (rd_clk),
    .rd_rst_n(rd_rst_n),
    .rd_en   (rd_en),
    .rd_data (rd_data),
    .empty   (empty)
  );

  // ----------------- clocks -----------------
  initial begin
    wr_clk = 0;
    forever #5 wr_clk = ~wr_clk;      // 100 MHz
  end

  initial begin
    rd_clk = 0;
    forever #7 rd_clk = ~rd_clk;      // ~71 MHz
  end
integer wcount;
  // ------------- single control block -------------
  initial begin
    // init
    wr_rst_n = 0;
    rd_rst_n = 0;
    wr_en    = 0;
    rd_en    = 0;
    wr_data  = 0;

    // wait past GSR in post-impl sim
    #200;

    // release async resets
    wr_rst_n = 1;
    rd_rst_n = 1;
    $display("[%0t] Resets deasserted", $time);

    // give the DUT a couple of clocks
    repeat (2) @(posedge wr_clk);
    repeat (2) @(posedge rd_clk);

  //---------------------------------------------------------------------
// TEST 1: FILL FIFO COMPLETELY ? FULL ASSERTION
//---------------------------------------------------------------------
$display("\n--- TEST 1: Filling FIFO to FULL ---");


wcount = 0;

wr_en = 1;
while (!full) begin
    wr_data = wcount[7:0];
    @(posedge wr_clk);
    $display("[WR] t=%0t  WROTE %0d", $time, wr_data);
    wcount=wcount + 1;
end

wr_en = 0;
$display("[TB] FULL asserted after %0d writes", wcount);

// Try one illegal write (should NOT be accepted)
@(posedge wr_clk);
wr_en   = 1;
wr_data = 8'hAA;
@(posedge wr_clk);
wr_en = 0;
$display("[TB] Attempted extra write when FULL (should have been ignored)");

//---------------------------------------------------------------------
// TEST 2: Drain FIFO ? EMPTY ASSERTION
//---------------------------------------------------------------------
$display("\n--- TEST 2: Draining FIFO to EMPTY ---");

rd_en = 1;
while (!empty) begin
    @(posedge rd_clk);
    $display("[RD] t=%0t  READ %0d", $time, rd_data);
end
rd_en = 0;

$display("[TB] EMPTY asserted");


    #100;
    $display("\n--- END OF TEST ---");
    $finish;
  end

  // ------------- monitors -------------
  always @(posedge wr_clk) begin
    $display("WR t=%0t | wr_en=%b wr_data=%h full=%b",
              $time, wr_en, wr_data, full);
  end

  always @(posedge rd_clk) begin
    $display("RD t=%0t | rd_en=%b rd_data=%h empty=%b",
              $time, rd_en, rd_data, empty);
  end

endmodule
