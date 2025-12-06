# Synchronous FIFO – RTL + Formal Verification
This directory contains the RTL implementation of a Synchronous FIFO and a complete formal verification environment built using SymbiYosys (SBY).The verification proves correctness of pointers, flags, occupancy, and data ordering.For a full explanation of the proofs, refer to the included PDF report.


# Tools Used

Yosys – HDL synthesis & formal elaboration

SymbiYosys (SBY) – formal verification flow

Boolector – SMT solver

GTKWave – waveform viewing for counterexample traces

Works with:
OSS CAD Suite (recommended)

# How to Run the Formal Verification
Inside synchronous/ run:
sby -f fifo_sync.sby

After running:

Proof results appear under: synchronous/fifo_sync/

Waveforms (only if a failure occurs) in: engine_0/trace.vcd

Logs stored in: model/ and engine_0/

A successful run prints:

SBY ... DONE (PASS, rc=0)

Verification Results (Screenshots)

synchronous/Results/
    Pasted image.png
    Pasted image (2).png

    synchronous/Results/
    Pasted image.png
    Pasted image (2).png





