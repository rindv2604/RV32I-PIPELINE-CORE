`timescale 1ns/1ps

module hazard_unit (
    input  logic       idex_memread,
    input  logic [4:0] idex_rd,
    input  logic [4:0] ifid_rs1,
    input  logic [4:0] ifid_rs2,
    output logic       pc_write,
    output logic       ifid_write,
    output logic       idex_flush
);
    always @* begin
        pc_write   = 1'b1;
        ifid_write = 1'b1;
        idex_flush = 1'b0;

        // load-use hazard
        if (idex_memread && (idex_rd != 5'd0) &&
           ((idex_rd == ifid_rs1) || (idex_rd == ifid_rs2))) begin
            pc_write   = 1'b0;
            ifid_write = 1'b0;
            idex_flush = 1'b1; // inject bubble
        end
    end
endmodule
