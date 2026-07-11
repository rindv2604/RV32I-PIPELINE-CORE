`timescale 1ns/1ps

module tb_cpu_top;
    localparam int CLK_PERIOD_NS = 10;

    logic        clk;
    logic        rst_n;
    logic [31:0] pc_debug;
    logic        instr_valid;

    int          max_cycles;
    int unsigned cycle = 0;
    int          done_reg;
    logic [31:0] done_value;
    logic [31:0] expected [0:31];
    bit          expected_valid [0:31];
    int          errors;
    string       test_name;
    string       vcd_file;
    string       plusarg_fmt;

    cpu_top dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .pc_debug    (pc_debug),
        .instr_valid (instr_valid)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    function automatic logic [31:0] read_reg(input int idx);
        begin
            if (idx == 0)
                read_reg = 32'd0;
            else
                read_reg = dut.u_regfile.rf[idx];
        end
    endfunction

    task automatic load_expectations;
        int i;
        logic [31:0] plusarg_value;
        begin
            for (i = 0; i < 32; i++) begin
                expected[i] = 32'd0;
                expected_valid[i] = 1'b0;
                $sformat(plusarg_fmt, "EXPECT_X%0d=%%h", i);
                if ($value$plusargs(plusarg_fmt, plusarg_value)) begin
                    expected[i] = plusarg_value;
                    expected_valid[i] = 1'b1;
                end
            end
        end
    endtask

    task automatic check_expectations;
        int i;
        logic [31:0] actual;
        begin
            errors = 0;
            for (i = 0; i < 32; i++) begin
                if (expected_valid[i]) begin
                    actual = read_reg(i);
                    if (actual !== expected[i]) begin
                        $error("[%0s] x%0d mismatch: expected 0x%08h, got 0x%08h",
                               test_name, i, expected[i], actual);
                        errors++;
                    end
                end
            end
        end
    endtask

    always @(posedge clk) begin
        if (!rst_n)
            cycle <= 0;
        else
            cycle <= cycle + 1;
    end

    always @(negedge clk) begin
        if (rst_n && $test$plusargs("TRACE")) begin
            $display("cycle=%0d valid=%0b pc_if=0x%08h id=0x%08h ex=0x%08h mem=0x%08h wb=0x%08h mem_rd=%0d mem_rw=%0b mem_mr=%0b mem_mw=%0b mem_addr=0x%08h mem_wdata=0x%08h mem_rdata=0x%08h wb_rd=%0d wb_we=%0b wb_data=0x%08h fwd_a=%0b fwd_b=%0b",
                     cycle, instr_valid, dut.pc_q, dut.id_instr, dut.ex_instr, dut.mem_instr, dut.wb_instr,
                     dut.mem_rd, dut.mem_reg_write, dut.mem_mem_read, dut.mem_mem_write,
                     dut.mem_alu_result, dut.mem_store_data, dut.mem_read_data,
                     dut.memwb_rd, dut.memwb_reg_write, dut.wb_data,
                     dut.forward_a, dut.forward_b);
        end
    end

    initial begin
        rst_n      = 1'b0;
        max_cycles = 200;
        done_reg   = 31;
        done_value = 32'd1;
        test_name  = "cpu_top";

        if ($value$plusargs("TEST_NAME=%s", test_name)) begin
        end
        if ($value$plusargs("MAX_CYCLES=%d", max_cycles)) begin
        end
        if ($value$plusargs("DONE_REG=%d", done_reg)) begin
        end
        if ($value$plusargs("DONE_VALUE=%h", done_value)) begin
        end
        if ($value$plusargs("VCD=%s", vcd_file)) begin
            $dumpfile(vcd_file);
            $dumpvars(0, tb_cpu_top);
            $dumpvars(1, tb_cpu_top.dut.u_regfile);  // Dump 1 level deep
        end

        load_expectations();

        repeat (5) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        while (cycle < max_cycles) begin
            @(negedge clk);
            if (read_reg(done_reg) === done_value) begin
                repeat (2) @(negedge clk);
                check_expectations();
                if (errors != 0)
                    $fatal(1, "[%0s] FAILED with %0d error(s)", test_name, errors);

                $display("[%0s] PASS at cycle %0d pc=0x%08h", test_name, cycle, pc_debug);
                $finish;
            end
        end

        $fatal(1, "[%0s] TIMEOUT after %0d cycles waiting for x%0d = 0x%08h",
               test_name, max_cycles, done_reg, done_value);
    end
endmodule
