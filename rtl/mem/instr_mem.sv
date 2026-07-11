`timescale 1ns/1ps

module instr_mem #(
    parameter int ADDR_WIDTH = 10,
    parameter INIT_FILE = ""
) (
    input  logic [31:0] addr,
    output logic [31:0] instr
);
    localparam int WORDS = 1 << ADDR_WIDTH;
    localparam logic [31:0] NOP = 32'h0000_0013;

    logic [31:0] word_addr;

    assign word_addr = {2'b00, addr[31:2]};

`ifdef __pnr__
    always @* begin
        case (word_addr)
            32'd0:   instr = 32'h0073_02b3;
            32'd1:   instr = 32'h4062_8e33;
            32'd2:   instr = 32'h000e_0663;
            32'd3:   instr = 32'h0000_0e93;
            32'd4:   instr = 32'h0080_006f;
            32'd5:   instr = 32'h0010_0e93;
            32'd6:   instr = 32'h00a0_0893;
            32'd7:   instr = 32'h0000_0073;
            default: instr = NOP;
        endcase
    end
`else
    logic [31:0] mem [0:WORDS-1];
    string init_file;
    int i;

    initial begin
        for (i = 0; i < WORDS; i++) begin
            mem[i] = NOP;
        end

        if ($value$plusargs("IMEM=%s", init_file)) begin
            $readmemh(init_file, mem);
        end else if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    always @* begin
        if (word_addr < WORDS)
            instr = mem[word_addr[ADDR_WIDTH-1:0]];
        else
            instr = NOP;
    end
`endif
endmodule
