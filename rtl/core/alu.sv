`timescale 1ns/1ps

module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  alu_sel,
    output logic [31:0] y,
    output logic        zero
);
    always @* begin
        case (alu_sel)
            4'b0000: y = a + b;                          // ADD
            4'b0001: y = a - b;                          // SUB
            4'b0010: y = a & b;                          // AND
            4'b0011: y = a | b;                          // OR
            4'b0100: y = a ^ b;                          // XOR
            4'b0101: y = a << b[4:0];                    // SLL
            4'b0110: y = a >> b[4:0];                    // SRL
            4'b0111: y = $signed(a) >>> b[4:0];          // SRA
            4'b1000: y = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT
            4'b1001: y = (a < b) ? 32'd1 : 32'd0;        // SLTU
            default: y = 32'h0;
        endcase
    end
    assign zero = (y == 32'd0);
endmodule
