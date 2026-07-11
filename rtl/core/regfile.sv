`timescale 1ns/1ps
module regfile (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        we,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,
    input  logic [31:0] wd,
    output logic [31:0] rd1,
    output logic [31:0] rd2
);
    logic [31:0] rf [0:31];
    integer i;

    assign rd1 = (rs1 == 5'd0) ? 32'd0 :
                 (we && (rd != 5'd0) && (rd == rs1)) ? wd : rf[rs1];
    assign rd2 = (rs2 == 5'd0) ? 32'd0 :
                 (we && (rd != 5'd0) && (rd == rs2)) ? wd : rf[rs2];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<32; i++) rf[i] <= 32'd0;
        end else if (we && rd != 5'd0) begin
            rf[rd] <= wd;
        end
    end
endmodule
