# Synchronous FIFO – RTL + Formal Verification
This directory contains the RTL design of a Synchronous FIFO along with a complete formal verification environment built using Yosys + SymbiYosys (SBY).
All core FIFO behaviors—pointer movement, occupancy, full/empty logic, and data integrity—are formally proven.

📄 For full detailed explanations, refer to the report:
➡️ FIFO_Formal_Verification_Report_Manish_Ranjan.pdf

**[`FIFO_Formal_Verification_Report_Manish_Ranjan.pdf`](fifo-verilog/synchronous
/FIFO_Formal_Verification_Report_Manish_Ranjan.pdf)**

🔧 Tools Used

Yosys – Verilog synthesis & formal elaboration

SymbiYosys (SBY) – formal job orchestration

Boolector – SMT solver

GTKWave – waveform viewer

OSS CAD Suite – Bundled toolchain (recommended)

# How to Run the Formal Verification
Inside synchronous/ run:

sby -f fifo_sync.sby

After running:

| Output Type                                      | Location                                     |
| ------------------------------------------------ | -------------------------------------------- |
| Formal job directory                             | `synchronous/fifo_sync/`                     |
| Logs                                             | `synchronous/fifo_sync/model/` + `engine_0/` |
| Counterexample waveform (only if failure occurs) | `engine_0/trace.vcd`                         |
| Solver result                                    | printed to terminal                          |


A successful proof ends with:

SBY ... DONE (PASS, rc=0)


📊 Verification Results

📂 synchronous/Results/

These show:

SymbiYosys running all property checks

Boolector solving each step successfully

Final PASS status

No counterexamples generated







