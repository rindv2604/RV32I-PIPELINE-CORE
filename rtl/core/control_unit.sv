`timescale 1ns/1ps

module control_unit (
    input  logic [31:0] instr,
    output logic        reg_write,
    output logic        mem_read,
    output logic        mem_write,
    output logic        mem_to_reg,
    output logic        alu_src,
    output logic        branch,
    output logic        jump,
    output logic [3:0]  alu_sel,
    output logic [1:0]  wb_sel,
    output logic [1:0]  alu_a_sel,
    output logic [2:0]  imm_sel,
    output logic        jalr,
    output logic        use_rs1,
    output logic        use_rs2,
    output logic        valid
);
    localparam logic [1:0] WB_ALU = 2'd0;
    localparam logic [1:0] WB_MEM = 2'd1;
    localparam logic [1:0] WB_PC4 = 2'd2;

    localparam logic [1:0] ALUA_RS1  = 2'd0;
    localparam logic [1:0] ALUA_PC   = 2'd1;
    localparam logic [1:0] ALUA_ZERO = 2'd2;

    localparam logic [2:0] IMM_I = 3'd0;
    localparam logic [2:0] IMM_S = 3'd1;
    localparam logic [2:0] IMM_B = 3'd2;
    localparam logic [2:0] IMM_U = 3'd3;
    localparam logic [2:0] IMM_J = 3'd4;

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

    always @* begin
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        mem_to_reg= 1'b0;
        alu_src   = 1'b0;
        branch    = 1'b0;
        jump      = 1'b0;
        alu_sel   = 4'b0000;
        wb_sel    = WB_ALU;
        alu_a_sel = ALUA_RS1;
        imm_sel   = IMM_I;
        jalr      = 1'b0;
        use_rs1   = 1'b0;
        use_rs2   = 1'b0;
        valid     = 1'b0;

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1'b1;
                use_rs1   = 1'b1;
                use_rs2   = 1'b1;
                valid     = 1'b1;
                case ({funct7, funct3})
                    10'b0000000_000: alu_sel = 4'b0000; // ADD
                    10'b0100000_000: alu_sel = 4'b0001; // SUB
                    10'b0000000_111: alu_sel = 4'b0010; // AND
                    10'b0000000_110: alu_sel = 4'b0011; // OR
                    10'b0000000_100: alu_sel = 4'b0100; // XOR
                    10'b0000000_001: alu_sel = 4'b0101; // SLL
                    10'b0000000_101: alu_sel = 4'b0110; // SRL
                    10'b0100000_101: alu_sel = 4'b0111; // SRA
                    10'b0000000_010: alu_sel = 4'b1000; // SLT
                    10'b0000000_011: alu_sel = 4'b1001; // SLTU
                    default:         alu_sel = 4'b0000;
                endcase
            end

            7'b0010011: begin // I-type ALU (addi/xori/ori/andi...)
                reg_write = 1'b1;
                alu_src   = 1'b1;
                use_rs1   = 1'b1;
                imm_sel   = IMM_I;
                valid     = 1'b1;
                case (funct3)
                    3'b000: alu_sel = 4'b0000; // ADDI
                    3'b100: alu_sel = 4'b0100; // XORI
                    3'b110: alu_sel = 4'b0011; // ORI
                    3'b111: alu_sel = 4'b0010; // ANDI
                    3'b010: alu_sel = 4'b1000; // SLTI
                    3'b011: alu_sel = 4'b1001; // SLTIU
                    3'b001: alu_sel = 4'b0101; // SLLI
                    3'b101: alu_sel = (funct7[5]) ? 4'b0111 : 4'b0110; // SRAI/SRLI
                    default: alu_sel = 4'b0000;
                endcase
            end

            7'b0000011: begin // LOAD
                reg_write = 1'b1;
                mem_read  = 1'b1;
                mem_to_reg= 1'b1;
                alu_src   = 1'b1;
                wb_sel    = WB_MEM;
                use_rs1   = 1'b1;
                imm_sel   = IMM_I;
                valid     = 1'b1;
                alu_sel   = 4'b0000; // base + imm
            end

            7'b0100011: begin // STORE
                mem_write = 1'b1;
                alu_src   = 1'b1;
                use_rs1   = 1'b1;
                use_rs2   = 1'b1;
                imm_sel   = IMM_S;
                valid     = 1'b1;
                alu_sel   = 4'b0000; // base + imm
            end

            7'b1100011: begin // BRANCH
                branch    = 1'b1;
                alu_src   = 1'b1;
                alu_a_sel = ALUA_PC;
                use_rs1   = 1'b1;
                use_rs2   = 1'b1;
                imm_sel   = IMM_B;
                valid     = 1'b1;
                alu_sel   = 4'b0000; // branch target = pc + imm
            end

            7'b1101111: begin // JAL
                reg_write = 1'b1;
                jump      = 1'b1;
                alu_src   = 1'b1;
                alu_a_sel = ALUA_PC;
                wb_sel    = WB_PC4;
                imm_sel   = IMM_J;
                valid     = 1'b1;
                alu_sel   = 4'b0000;
            end

            7'b1100111: begin // JALR
                reg_write = 1'b1;
                jump      = 1'b1;
                jalr      = 1'b1;
                alu_src   = 1'b1;
                wb_sel    = WB_PC4;
                use_rs1   = 1'b1;
                imm_sel   = IMM_I;
                valid     = 1'b1;
                alu_sel   = 4'b0000;
            end

            7'b0110111: begin // LUI
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_a_sel = ALUA_ZERO;
                imm_sel   = IMM_U;
                valid     = 1'b1;
                alu_sel   = 4'b0000;
            end

            7'b0010111: begin // AUIPC
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_a_sel = ALUA_PC;
                imm_sel   = IMM_U;
                valid     = 1'b1;
                alu_sel   = 4'b0000;
            end

            default: ;
        endcase
    end
endmodule
