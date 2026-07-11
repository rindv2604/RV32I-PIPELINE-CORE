`timescale 1ns/1ps

module ex_mem (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [31:0] pc_in,
    input  logic [31:0] pc_plus4_in,
    input  logic [31:0] instr_in,
    input  logic [31:0] alu_result_in,
    input  logic [31:0] store_data_in,
    input  logic [4:0]  rd_in,
    input  logic [2:0]  funct3_in,
    input  logic        reg_write_in,
    input  logic        mem_read_in,
    input  logic        mem_write_in,
    input  logic        mem_to_reg_in,
    input  logic        valid_in,
    input  logic [1:0]  wb_sel_in,

    output logic [31:0] pc_out,
    output logic [31:0] pc_plus4_out,
    output logic [31:0] instr_out,
    output logic [31:0] alu_result_out,
    output logic [31:0] store_data_out,
    output logic [4:0]  rd_out,
    output logic [2:0]  funct3_out,
    output logic        reg_write_out,
    output logic        mem_read_out,
    output logic        mem_write_out,
    output logic        mem_to_reg_out,
    output logic        valid_out,
    output logic [1:0]  wb_sel_out
);
    localparam logic [31:0] NOP = 32'h0000_0013;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out         <= 32'd0;
            pc_plus4_out   <= 32'd4;
            instr_out      <= NOP;
            alu_result_out <= 32'd0;
            store_data_out <= 32'd0;
            rd_out         <= 5'd0;
            funct3_out     <= 3'd0;
            reg_write_out  <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            valid_out      <= 1'b0;
            wb_sel_out     <= 2'd0;
        end else begin
            pc_out         <= pc_in;
            pc_plus4_out   <= pc_plus4_in;
            instr_out      <= instr_in;
            alu_result_out <= alu_result_in;
            store_data_out <= store_data_in;
            rd_out         <= rd_in;
            funct3_out     <= funct3_in;
            reg_write_out  <= reg_write_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            valid_out      <= valid_in;
            wb_sel_out     <= wb_sel_in;
        end
    end
endmodule
