`timescale 1ns/1ps

module forwarding_unit (
    input  logic [4:0] rs1_ex,
    input  logic [4:0] rs2_ex,
    input  logic [4:0] rd_mem,
    input  logic [4:0] rd_wb,
    input  logic       regwrite_mem,
    input  logic       regwrite_wb,
    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);
    always @* begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        if (regwrite_mem && (rd_mem != 5'd0) && (rd_mem == rs1_ex))
            forward_a = 2'b10;
        else if (regwrite_wb && (rd_wb != 5'd0) && (rd_wb == rs1_ex))
            forward_a = 2'b01;

        if (regwrite_mem && (rd_mem != 5'd0) && (rd_mem == rs2_ex))
            forward_b = 2'b10;
        else if (regwrite_wb && (rd_wb != 5'd0) && (rd_wb == rs2_ex))
            forward_b = 2'b01;
    end
endmodule
