`timescale 1ns/1ps

module mem_wb (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [31:0] pc_in,
    input  logic [31:0] pc_plus4_in,
    input  logic [31:0] instr_in,
    input  logic [31:0] alu_result_in,
    input  logic [31:0] mem_read_data_in,
    input  logic [4:0]  rd_in,
    input  logic        reg_write_in,
    input  logic        valid_in,
    input  logic [1:0]  wb_sel_in,

    output logic [31:0] pc_out,
    output logic [31:0] pc_plus4_out,
    output logic [31:0] instr_out,
    output logic [31:0] alu_result_out,
    output logic [31:0] mem_read_data_out,
    output logic [4:0]  rd_out,
    output logic        reg_write_out,
    output logic        valid_out,
    output logic [1:0]  wb_sel_out
);
    localparam logic [31:0] NOP = 32'h0000_0013;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out            <= 32'd0;
            pc_plus4_out      <= 32'd4;
            instr_out         <= NOP;
            alu_result_out    <= 32'd0;
            mem_read_data_out <= 32'd0;
            rd_out            <= 5'd0;
            reg_write_out     <= 1'b0;
            valid_out         <= 1'b0;
            wb_sel_out        <= 2'd0;
        end else begin
            pc_out            <= pc_in;
            pc_plus4_out      <= pc_plus4_in;
            instr_out         <= instr_in;
            alu_result_out    <= alu_result_in;
            mem_read_data_out <= mem_read_data_in;
            rd_out            <= rd_in;
            reg_write_out     <= reg_write_in;
            valid_out         <= valid_in;
            wb_sel_out        <= wb_sel_in;
        end
    end
endmodule
