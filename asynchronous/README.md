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

Example Gray sequence (1-bit change each step):

0110 → 0111 → 0101 → 0100 → 1100 → ...

This massively improves CDC safety.

---

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

---

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

```verilog
wbin_next = wr_bin + (wr_en & ~full);
wgnext    = bin2gray(wbin_next);

rbin_next = rd_bin + (rd_en & ~empty);
rgnext    = bin2gray(rbin_next);

Using next pointer values ensures FULL/EMPTY flags update in the same cycle as pointer increments.
