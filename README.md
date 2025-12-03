📘 1. Asynchronous FIFO Theory (Summary)

An asynchronous FIFO transfers data between two independent, unrelated clock domains:

Write side: wr_clk

Read side: rd_clk

Such FIFOs must handle:

metastability

pointer corruption

safe multi-bit synchronization

correct FULL/EMPTY detection

overflow/underflow protection

This implementation uses a standard and proven architecture.

1.1 Why Use Gray Code Pointers?

Binary counters can change multiple bits at once:

0111 → 1000   (4 bits change)


If sampled mid-transition by another clock domain, this can cause incorrect FULL/EMPTY detection.

✔ Gray code solves this

Only one bit changes per increment

Sampling mid-transition produces at most 1-bit error

Ensures safe pointer synchronization

Example Gray sequence:

0110 → 0111 → 0101 → 0100 → 1100 → ...

1.2 Pointer Width and Structure

For a FIFO of depth DEPTH = 2^ASIZE:

Pointer width: P = ASIZE + 1

Lower ASIZE bits → memory address

MSB → wrap detection (distinguishes FULL vs EMPTY)

Each pointer exists in two forms:

Purpose	Format
Incrementing & addressing	Binary
Crossing clock domain	Gray code
1.3 Pointer Synchronizers (CDC)

Each Gray pointer is synchronized into the opposite domain via two flip-flops:

// Read pointer into write clock domain
wrptr_s1 <= rd_gray;
wrptr_s2 <= wrptr_s1;

// Write pointer into read clock domain
rwptr_s1 <= wr_gray;
rwptr_s2 <= rwptr_s1;


Only the second stage (*_s2) is used.

This removes metastability and produces stable timing.

1.4 Next-Pointer Logic (STA-Friendly)
wbin_next = wr_bin + (wr_en & ~full);
wgnext    = bin2gray(wbin_next);

rbin_next = rd_bin + (rd_en & ~empty);
rgnext    = bin2gray(rbin_next);


Using next pointer values ensures FULL/EMPTY flags update in the same cycle as the pointer increment.

1.5 FULL Condition (Gray Logic)

Industry-standard FULL detection rule:

wfull_reg <= (wgnext == {~wrptr_sync[P-1:P-2], wrptr_sync[P-3:0]});


Why invert the top two bits?

When write pointer wraps and catches the read pointer,

The Gray codes only differ in the MSBs

This comparison correctly detects FULL without ambiguity

1.6 EMPTY Condition

Empty when the next read pointer equals the synchronized write pointer:

rempty_reg <= (rgnext == rwptr_sync);

1.7 Memory Behavior
Write (write-clock domain)
if (wr_en && !full)
    mem[waddr] <= wr_data;

Read (read-clock domain)
rd_data <= mem[raddr];


The last read value is held stable when empty = 1.

1.8 Why FIFO Must Be Power-of-2 Deep

Gray code wraps cleanly only for 2^N sizes.

For non-power-of-2 depths:

Multi-bit transitions appear

Gray-code one-bit-change property breaks

FULL/EMPTY detection becomes unsafe

🧪 2. Testbench Description

The testbench performs a complete verification of FIFO behavior.

2.1 Reset Handling (includes Vivado GSR)

Vivado post-implementation simulation includes a Global Set/Reset (GSR) active for ~100 ns.

The TB waits long enough before releasing reset:

#200;
wr_rst_n = 1;
rd_rst_n = 1;


This ensures FIFO registers are not held in reset by GSR.

2.2 Clock Generation

Two asynchronous clocks:

wr_clk = 100 MHz  (10 ns period)
rd_clk ≈ 71 MHz   (14 ns period)


This simulates true async CDC behavior.

2.3 Writing Until FULL

The testbench writes incrementing values until the FIFO asserts FULL:

wcount = 0;
wr_en = 1;

while (!full) begin
    wr_data = wcount[7:0];
    @(posedge wr_clk);
    wcount = wcount + 1;
end

wr_en = 0;

2.4 Illegal Write Test (Overflow Protection)

After FULL, TB attempts an extra write:

wr_en   = 1;
wr_data = 8'hAA;


But FIFO write port uses:

if (wr_en && !full)
    mem[waddr] <= wr_data;


Since full = 1, the write is ignored.

This verifies overflow protection.

2.5 Reading Until EMPTY
rd_en = 1;

while (!empty)
    @(posedge rd_clk);

rd_en = 0;


FIFO drains correctly and asserts EMPTY.

📈 3. Output Waveforms (Post-Implementation)

Waveforms included in:

Outputwaveform/
