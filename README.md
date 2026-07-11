# RV32I Pipeline Core

A 5-stage pipelined RISC-V RV32I processor core designed in SystemVerilog.

## Features & Microarchitecture

* **RTL-level datapath:** Illustrating stage partitioning (IF, ID, EX, MEM, WB), pipeline registers, control signal propagation, ALU execution, memory access, and branch resolution.
* **Hazard Resolution:** Supports forwarding and stalling to handle data and control hazards.

<img width="1628" height="966" alt="rv32i-pipepline" src="https://github.com/user-attachments/assets/971911c5-954c-4127-bd9c-aab4ec443e78" />


---

## Toolchain & Simulation Results

### Simulation Icarus Verilog
The simulation uses `rtl/tbench.sv` (`tb_cpu_top`) to run verification programs.

<img width="2218" height="1158" alt="wave" src="https://github.com/user-attachments/assets/66475a08-6e8a-4c78-934d-504eee10a0b2" />


### Timing Analysis Results (LibreLane Flow)
Physical-design and timing reports from the ASIC flow using LibreLane.

<img width="1625" height="370" alt="timing" src="https://github.com/user-attachments/assets/410966d4-4a96-4633-b10b-ab0a15c2d5f5" />




