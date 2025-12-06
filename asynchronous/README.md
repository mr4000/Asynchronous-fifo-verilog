
---

#  1. Asynchronous FIFO Theory (Summary)

An **asynchronous FIFO** transfers data between two independent, unrelated clock domains:

- **Write side:** `wr_clk`
- **Read side:** `rd_clk`

Such FIFOs must handle:

- metastability,
- pointer corruption,
- safe multi-bit synchronization,
- correct FULL/EMPTY detection,
- overflow/underflow protection.

This implementation uses the standard and proven architecture.

---

##  1.1 Why Use Gray Code Pointers?

Binary counters can change multiple bits at once:

0111 → 1000 (4 bits change)


If sampled mid-transition by another clock domain, this produces corrupted values.

**Gray code solves this**:

- Only **one bit changes per increment**
- Sampling mid-transition produces at most 1-bit uncertainty
- Correct FULL/EMPTY detection becomes reliable

  Gray code changes only 1 bit at a time
  Example Gray sequence:
  0110 → 0111 → 0101 → 0100 → 1100 → ...

This massively improves CDC safety.
  

## 1.2 Pointer Width and Structure

For a FIFO of depth `DEPTH = 2^ASIZE`:

- pointer width: **P = ASIZE + 1**
- lower ASIZE bits → memory address  
- MSB → wrap detection (used to distinguish FULL vs EMPTY)

Each pointer exists in two forms:

| Purpose                   | Format    |
| ------------------------- | --------- |
| Incrementing & addressing | Binary    |
| Crossing clock domain     | Gray code |


##  1.3 Pointer Synchronizers (CDC)

Each pointer is synchronized into the opposite domain via two flip-flops:

```verilog
// Read pointer into write clock domain
wrptr_s1 <= rd_gray;
wrptr_s2 <= wrptr_s1;

// Write pointer into read clock domain
rwptr_s1 <= wr_gray;
rwptr_s2 <= rwptr_s1;

Only the second stage (*_s2) is used.

This removes metastability and produces stable timing.

## 1.4 Next-Pointer Logic (STA-Friendly)
wbin_next = wr_bin + (wr_en & ~full);
wgnext    = bin2gray(wbin_next);

rbin_next = rd_bin + (rd_en & ~empty);
rgnext    = bin2gray(rbin_next);


Using next pointer values ensures FULL/EMPTY flags update in the same clock cycle as pointer increments.

1.5  FULL Condition (Gray Logic)

This is the industry-standard rule:

wfull_reg <= (wgnext == {~wrptr_sync[P-1:P-2], wrptr_sync[P-3:0]});

Why invert top two bits?

When write pointer wraps around and catches read pointer,

The Gray codes differ only in their MSBs,

This condition detects true FIFO FULL without ambiguity.


1.6 EMPTY Condition

rempty_reg <= (rgnext == rwptr_sync);

This checks whether the next read pointer equals the synchronized write pointer.

1.7 Memory Behavior

Write (write-clock domain):

if (wr_en && !full)
    mem[waddr] <= wr_data;

Read (read-clock domain):

rd_data <= mem[raddr];

The last read value is held stable when empty=1.

1.8 Why FIFO Depth Must Be a Power-of-2

Gray code wraps cleanly only for 2^N sizes.

Non-power-of-2 FIFOs break the one-bit-change rule and produce invalid transitions.

2. Testbench Description

The testbench performs a complete verification of the FIFO:

2.1 Reset Handling (includes Vivado GSR)

Vivado post-implementation simulation includes a Global Set/Reset (GSR) active for ~100 ns.

The TB waits:

#200;
wr_rst_n = 1;
rd_rst_n = 1;

This ensures FIFO registers are not held in reset by GSR

2.2 Clock Generation

wr_clk = 100 MHz (10 ns)
rd_clk ≈ 71 MHz (14 ns)

Two independent clocks → fully asynchronous behavior.

2.3 Writing Until FULL


The TB writes incrementing values until the FIFO asserts full:

wcount = 0;
wr_en = 1;
while (!full) begin
    wr_data = wcount[7:0];
    @(posedge wr_clk);
    $display("[WR] t=%0t  WROTE %0d", $time, wr_data);
    wcount=wcount + 1;
end
wr_en = 0;

2.4 Illegal write test 

After FULL, TB drives:

wr_en = 1;
wr_data = 8'hAA;

But because:

if (wr_en && !full) mem[waddr] <= wr_data;


the value AA is NOT stored.
This validates overflow protection.

Reading Until EMPTY
rd_en = 1;
while (!empty) @(posedge rd_clk);
rd_en = 0;


The FIFO drains completely and asserts empty

3.Output Waveforms (Post-Implementation)

Waveforms are included in:

Outputwaveform/

Full_condition.png

Shows:

write pointer incrementing

FIFO becomes FULL

extra write “AA” is rejected

FULL flag asserted correctly

Empty_condition.png

Shows:

read pointer incrementing

FIFO drains completely

EMPTY flag asserted correctly

no underflow events

These waveforms confirm correct pointer synchronization and status flag logic after implementation.

4. Summary

This project demonstrates a fully functional asynchronous FIFO using:

Gray-code pointers

Dual clock domains

Safe pointer synchronization

Correct FULL and EMPTY detection

Overflow and underflow protection

The implementation has been validated using:

Behavioral simulation

Post-synthesis simulation

Post-implementation timing simulation

This is the canonical FIFO architecture used in industry-grade CDC designs.
