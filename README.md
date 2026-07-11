# RV32I Pipeline Core

The simulation uses `rtl/tbench.sv` (`tb_cpu_top`) and Icarus Verilog.

Run the reference program and the pipeline hazard regression with:

```sh
make test
```

Run only the program from the reference repository with:

```sh
make test-reference
```

Add `+TRACE` to a `vvp` command for a cycle trace, or
`+VCD=build/wave.vcd` to write a waveform.

Generate and open the reference waveform with:

```sh
make wave
make view-wave
```

Run a LibreLane synthesis check or the complete physical-design flow with:

```sh
make librelane-synth
make librelane
```
