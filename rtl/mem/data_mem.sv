`timescale 1ns/1ps

module data_mem #(
    parameter int DATA_BYTES = 1024,
    parameter logic [31:0] DATA_BASE = 32'h1000_0000
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [31:0] addr,
    input  logic        early_mem_read,
    input  logic [31:0] early_addr,
    input  logic [31:0] write_data,
    input  logic [2:0]  funct3,
    output logic [31:0] read_data
);
    localparam logic [2:0] LB  = 3'b000;
    localparam logic [2:0] LH  = 3'b001;
    localparam logic [2:0] LW  = 3'b010;
    localparam logic [2:0] LBU = 3'b100;
    localparam logic [2:0] LHU = 3'b101;

    logic       addr_valid;
    logic [31:0] offset;
`ifdef __pnr__
    logic        early_addr_valid;
    logic [31:0] read_word;
    logic [31:0] shifted_read_word;
    logic [31:0] shifted_write_data;
    logic [3:0]  write_mask;
`else
    logic [7:0] mem [0:DATA_BYTES-1];
    string init_file;
    int i;
`endif

    assign addr_valid = (addr >= DATA_BASE) && (addr < (DATA_BASE + DATA_BYTES));
    assign offset = addr - DATA_BASE;

`ifdef __pnr__
    assign early_addr_valid = (early_addr >= DATA_BASE) &&
                              (early_addr < (DATA_BASE + DATA_BYTES));
    assign shifted_read_word = read_word >> ({3'd0, addr[1:0]} * 8);

    always @* begin
        shifted_write_data = write_data << ({3'd0, addr[1:0]} * 8);
        case (funct3[1:0])
            2'b00:   write_mask = 4'b0001 << addr[1:0];
            2'b01:   write_mask = 4'b0011 << addr[1:0];
            2'b10:   write_mask = 4'b1111;
            default: write_mask = 4'b0000;
        endcase
    end

    sky130_sram_1kbyte_1rw1r_32x256_8 u_dmem (
        .clk0   (clk),
        .csb0   (!(rst_n && mem_write && addr_valid)),
        .web0   (1'b0),
        .wmask0 (write_mask),
        .addr0  (addr[9:2]),
        .din0   (shifted_write_data),
        .dout0  (),
        .clk1   (clk),
        .csb1   (!(rst_n && early_mem_read && early_addr_valid)),
        .addr1  (early_addr[9:2]),
        .dout1  (read_word)
    );

    always @* begin
        read_data = 32'd0;
        if (mem_read && addr_valid) begin
            case (funct3)
                LB:  read_data = {{24{shifted_read_word[7]}}, shifted_read_word[7:0]};
                LH:  read_data = {{16{shifted_read_word[15]}}, shifted_read_word[15:0]};
                LW:  read_data = read_word;
                LBU: read_data = {24'd0, shifted_read_word[7:0]};
                LHU: read_data = {16'd0, shifted_read_word[15:0]};
                default: read_data = 32'd0;
            endcase
        end
    end
`else
    initial begin
        for (i = 0; i < DATA_BYTES; i++) begin
            mem[i] = 8'd0;
        end

        if ($value$plusargs("DMEM=%s", init_file)) begin
            $readmemh(init_file, mem);
        end
    end
    always_ff @(posedge clk) begin
        if (rst_n && mem_write && addr_valid) begin
            case (funct3[1:0])
                2'b00: begin
                    mem[offset] <= write_data[7:0];
                end
                2'b01: begin
                    if (offset + 1 < DATA_BYTES) begin
                        mem[offset]     <= write_data[7:0];
                        mem[offset + 1] <= write_data[15:8];
                    end
                end
                2'b10: begin
                    if (offset + 3 < DATA_BYTES) begin
                        mem[offset]     <= write_data[7:0];
                        mem[offset + 1] <= write_data[15:8];
                        mem[offset + 2] <= write_data[23:16];
                        mem[offset + 3] <= write_data[31:24];
                    end
                end
                default: ;
            endcase
        end
    end

    always @* begin
        read_data = 32'd0;

        if (mem_read && addr_valid) begin
            case (funct3)
                LB: begin
                    read_data = {{24{mem[offset][7]}}, mem[offset]};
                end
                LH: begin
                    if (offset + 1 < DATA_BYTES)
                        read_data = {{16{mem[offset + 1][7]}}, mem[offset + 1], mem[offset]};
                end
                LW: begin
                    if (offset + 3 < DATA_BYTES)
                        read_data = {mem[offset + 3], mem[offset + 2], mem[offset + 1], mem[offset]};
                end
                LBU: begin
                    read_data = {24'd0, mem[offset]};
                end
                LHU: begin
                    if (offset + 1 < DATA_BYTES)
                        read_data = {16'd0, mem[offset + 1], mem[offset]};
                end
                default: read_data = 32'd0;
            endcase
        end
    end
`endif
endmodule
