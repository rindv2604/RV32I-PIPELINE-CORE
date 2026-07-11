set_units -time ns

# Clock definition
create_clock [get_ports clk] -name clk -period 25.0

# Clock uncertainty
set_clock_uncertainty 0.5 [get_clocks clk]

# External interface budget
set_input_delay 5.0 -clock clk [get_ports rst_n]
set_output_delay 5.0 -clock clk [get_ports {pc_debug instr_valid}]
