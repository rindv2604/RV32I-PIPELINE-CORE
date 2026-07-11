`timescale 1ns/1ps

module cpu_top (
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] pc_debug,
    output logic        instr_valid
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

    logic [31:0] pc_q;
    logic [31:0] pc_plus4;
    logic [31:0] pc_next;
    logic [31:0] instr_f;
    logic        pc_write;
    logic        ifid_write;
    logic        idex_hazard_flush;
    logic        redirect;

    assign pc_plus4 = pc_q + 32'd4;
    assign pc_next  = redirect ? ex_redirect_target : pc_plus4;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc_q <= 32'd0;
        else if (pc_write || redirect)
            pc_q <= pc_next;
    end

    instr_mem u_instr_mem (
        .addr  (pc_q),
        .instr (instr_f)
    );

    logic [31:0] id_pc;
    logic [31:0] id_instr;

    if_id u_if_id (
        .clk       (clk),
        .rst_n     (rst_n),
        .write_en  (ifid_write),
        .flush     (redirect),
        .pc_in     (pc_q),
        .instr_in  (instr_f),
        .pc_out    (id_pc),
        .instr_out (id_instr)
    );

    logic [4:0] id_rs1;
    logic [4:0] id_rs2;
    logic [4:0] id_rd;
    logic [2:0] id_funct3;

    assign id_rs1    = id_instr[19:15];
    assign id_rs2    = id_instr[24:20];
    assign id_rd     = id_instr[11:7];
    assign id_funct3 = id_instr[14:12];

    logic        id_reg_write;
    logic        id_mem_read;
    logic        id_mem_write;
    logic        id_mem_to_reg;
    logic        id_alu_src;
    logic        id_branch;
    logic        id_jump;
    logic [3:0]  id_alu_sel;
    logic [1:0]  id_wb_sel;
    logic [1:0]  id_alu_a_sel;
    logic [2:0]  id_imm_sel;
    logic        id_jalr;
    logic        id_use_rs1;
    logic        id_use_rs2;
    logic        id_valid;

    control_unit u_control_unit (
        .instr       (id_instr),
        .reg_write   (id_reg_write),
        .mem_read    (id_mem_read),
        .mem_write   (id_mem_write),
        .mem_to_reg  (id_mem_to_reg),
        .alu_src     (id_alu_src),
        .branch      (id_branch),
        .jump        (id_jump),
        .alu_sel     (id_alu_sel),
        .wb_sel      (id_wb_sel),
        .alu_a_sel   (id_alu_a_sel),
        .imm_sel     (id_imm_sel),
        .jalr        (id_jalr),
        .use_rs1     (id_use_rs1),
        .use_rs2     (id_use_rs2),
        .valid       (id_valid)
    );

    logic [31:0] id_rs1_data;
    logic [31:0] id_rs2_data;
    logic [31:0] wb_data;
    logic [4:0]  memwb_rd;
    logic        memwb_reg_write;

    regfile u_regfile (
        .clk   (clk),
        .rst_n (rst_n),
        .we    (memwb_reg_write),
        .rs1   (id_rs1),
        .rs2   (id_rs2),
        .rd    (memwb_rd),
        .wd    (wb_data),
        .rd1   (id_rs1_data),
        .rd2   (id_rs2_data)
    );

    logic [31:0] imm_i;
    logic [31:0] imm_s;
    logic [31:0] imm_b;
    logic [31:0] imm_u;
    logic [31:0] imm_j;
    logic [31:0] id_imm;

    imm_gen u_immgen (
        .instr (id_instr),
        .imm_i (imm_i),
        .imm_s (imm_s),
        .imm_b (imm_b),
        .imm_u (imm_u),
        .imm_j (imm_j)
    );

    always @* begin
        case (id_imm_sel)
            IMM_S:   id_imm = imm_s;
            IMM_B:   id_imm = imm_b;
            IMM_U:   id_imm = imm_u;
            IMM_J:   id_imm = imm_j;
            default: id_imm = imm_i;
        endcase
    end

    logic [31:0] ex_pc;
    logic [31:0] ex_pc_plus4;
    logic [31:0] ex_instr;
    logic [31:0] ex_rs1_data;
    logic [31:0] ex_rs2_data;
    logic [31:0] ex_imm;
    logic [4:0]  ex_rs1;
    logic [4:0]  ex_rs2;
    logic [4:0]  ex_rd;
    logic [2:0]  ex_funct3;
    logic        ex_reg_write;
    logic        ex_mem_read;
    logic        ex_mem_write;
    logic        ex_mem_to_reg;
    logic        ex_alu_src;
    logic        ex_branch;
    logic        ex_jump;
    logic        ex_jalr;
    logic        ex_valid;
    logic [3:0]  ex_alu_sel;
    logic [1:0]  ex_wb_sel;
    logic [1:0]  ex_alu_a_sel;

    id_ex u_id_ex (
        .clk             (clk),
        .rst_n           (rst_n),
        .flush           (idex_hazard_flush || redirect),
        .pc_in           (id_pc),
        .pc_plus4_in     (id_pc + 32'd4),
        .instr_in        (id_instr),
        .rs1_data_in     (id_rs1_data),
        .rs2_data_in     (id_rs2_data),
        .imm_in          (id_imm),
        .rs1_in          (id_rs1),
        .rs2_in          (id_rs2),
        .rd_in           (id_rd),
        .funct3_in       (id_funct3),
        .reg_write_in    (id_reg_write),
        .mem_read_in     (id_mem_read),
        .mem_write_in    (id_mem_write),
        .mem_to_reg_in   (id_mem_to_reg),
        .alu_src_in      (id_alu_src),
        .branch_in       (id_branch),
        .jump_in         (id_jump),
        .jalr_in         (id_jalr),
        .valid_in        (id_valid),
        .alu_sel_in      (id_alu_sel),
        .wb_sel_in       (id_wb_sel),
        .alu_a_sel_in    (id_alu_a_sel),
        .pc_out          (ex_pc),
        .pc_plus4_out    (ex_pc_plus4),
        .instr_out       (ex_instr),
        .rs1_data_out    (ex_rs1_data),
        .rs2_data_out    (ex_rs2_data),
        .imm_out         (ex_imm),
        .rs1_out         (ex_rs1),
        .rs2_out         (ex_rs2),
        .rd_out          (ex_rd),
        .funct3_out      (ex_funct3),
        .reg_write_out   (ex_reg_write),
        .mem_read_out    (ex_mem_read),
        .mem_write_out   (ex_mem_write),
        .mem_to_reg_out  (ex_mem_to_reg),
        .alu_src_out     (ex_alu_src),
        .branch_out      (ex_branch),
        .jump_out        (ex_jump),
        .jalr_out        (ex_jalr),
        .valid_out       (ex_valid),
        .alu_sel_out     (ex_alu_sel),
        .wb_sel_out      (ex_wb_sel),
        .alu_a_sel_out   (ex_alu_a_sel)
    );

    logic [31:0] mem_pc;
    logic [31:0] mem_pc_plus4;
    logic [31:0] mem_instr;
    logic [31:0] mem_alu_result;
    logic [31:0] mem_store_data;
    logic [31:0] mem_read_data;
    logic [31:0] mem_forward_data;
    logic [4:0]  mem_rd;
    logic [2:0]  mem_funct3;
    logic        mem_reg_write;
    logic        mem_mem_read;
    logic        mem_mem_write;
    logic        mem_mem_to_reg;
    logic        mem_valid;
    logic [1:0]  mem_wb_sel;

    logic [31:0] wb_pc;
    logic [31:0] wb_pc_plus4;
    logic [31:0] wb_instr;
    logic [31:0] wb_alu_result;
    logic [31:0] wb_mem_read_data;
    logic        wb_valid;
    logic [1:0]  wb_wb_sel;

    logic [1:0]  forward_a;
    logic [1:0]  forward_b;
    logic [31:0] ex_forward_a_data;
    logic [31:0] ex_forward_b_data;
    logic [31:0] ex_alu_a;
    logic [31:0] ex_alu_b;
    logic [31:0] ex_alu_result;
    logic        ex_zero;
    logic        ex_branch_taken;
    logic [31:0] ex_redirect_target;

    always @* begin
        case (mem_wb_sel)
            WB_PC4:  mem_forward_data = mem_pc_plus4;
            default: mem_forward_data = mem_alu_result;
        endcase
    end

    forwarding_unit u_forwarding_unit (
        .rs1_ex       (ex_rs1),
        .rs2_ex       (ex_rs2),
        .rd_mem       (mem_rd),
        .rd_wb        (memwb_rd),
        .regwrite_mem (mem_reg_write),
        .regwrite_wb  (memwb_reg_write),
        .forward_a    (forward_a),
        .forward_b    (forward_b)
    );

    always @* begin
        case (forward_a)
            2'b10:   ex_forward_a_data = mem_forward_data;
            2'b01:   ex_forward_a_data = wb_data;
            default: ex_forward_a_data = ex_rs1_data;
        endcase

        case (forward_b)
            2'b10:   ex_forward_b_data = mem_forward_data;
            2'b01:   ex_forward_b_data = wb_data;
            default: ex_forward_b_data = ex_rs2_data;
        endcase
    end

    always @* begin
        case (ex_alu_a_sel)
            ALUA_PC:   ex_alu_a = ex_pc;
            ALUA_ZERO: ex_alu_a = 32'd0;
            default:   ex_alu_a = ex_forward_a_data;
        endcase

        ex_alu_b = ex_alu_src ? ex_imm : ex_forward_b_data;
    end

    alu u_alu (
        .a       (ex_alu_a),
        .b       (ex_alu_b),
        .alu_sel (ex_alu_sel),
        .y       (ex_alu_result),
        .zero    (ex_zero)
    );

    branch_unit u_branch_unit (
        .a      (ex_forward_a_data),
        .b      (ex_forward_b_data),
        .funct3 (ex_funct3),
        .taken  (ex_branch_taken)
    );

    assign redirect = (ex_branch && ex_branch_taken) || ex_jump;
    assign ex_redirect_target = ex_jalr ? {ex_alu_result[31:1], 1'b0} : ex_alu_result;

    ex_mem u_ex_mem (
        .clk             (clk),
        .rst_n           (rst_n),
        .pc_in           (ex_pc),
        .pc_plus4_in     (ex_pc_plus4),
        .instr_in        (ex_instr),
        .alu_result_in   (ex_alu_result),
        .store_data_in   (ex_forward_b_data),
        .rd_in           (ex_rd),
        .funct3_in       (ex_funct3),
        .reg_write_in    (ex_reg_write),
        .mem_read_in     (ex_mem_read),
        .mem_write_in    (ex_mem_write),
        .mem_to_reg_in   (ex_mem_to_reg),
        .valid_in        (ex_valid),
        .wb_sel_in       (ex_wb_sel),
        .pc_out          (mem_pc),
        .pc_plus4_out    (mem_pc_plus4),
        .instr_out       (mem_instr),
        .alu_result_out  (mem_alu_result),
        .store_data_out  (mem_store_data),
        .rd_out          (mem_rd),
        .funct3_out      (mem_funct3),
        .reg_write_out   (mem_reg_write),
        .mem_read_out    (mem_mem_read),
        .mem_write_out   (mem_mem_write),
        .mem_to_reg_out  (mem_mem_to_reg),
        .valid_out       (mem_valid),
        .wb_sel_out      (mem_wb_sel)
    );

    data_mem u_data_mem (
        .clk        (clk),
        .rst_n      (rst_n),
        .mem_read   (mem_mem_read),
        .mem_write  (mem_mem_write),
        .addr       (mem_alu_result),
        .early_mem_read(ex_mem_read),
        .early_addr (ex_alu_result),
        .write_data (mem_store_data),
        .funct3     (mem_funct3),
        .read_data  (mem_read_data)
    );

    mem_wb u_mem_wb (
        .clk              (clk),
        .rst_n            (rst_n),
        .pc_in            (mem_pc),
        .pc_plus4_in      (mem_pc_plus4),
        .instr_in         (mem_instr),
        .alu_result_in    (mem_alu_result),
        .mem_read_data_in (mem_read_data),
        .rd_in            (mem_rd),
        .reg_write_in     (mem_reg_write),
        .valid_in         (mem_valid),
        .wb_sel_in        (mem_wb_sel),
        .pc_out           (wb_pc),
        .pc_plus4_out     (wb_pc_plus4),
        .instr_out        (wb_instr),
        .alu_result_out   (wb_alu_result),
        .mem_read_data_out(wb_mem_read_data),
        .rd_out           (memwb_rd),
        .reg_write_out    (memwb_reg_write),
        .valid_out        (wb_valid),
        .wb_sel_out       (wb_wb_sel)
    );

    always @* begin
        case (wb_wb_sel)
            WB_MEM:  wb_data = wb_mem_read_data;
            WB_PC4:  wb_data = wb_pc_plus4;
            default: wb_data = wb_alu_result;
        endcase
    end

    logic [4:0] hazard_rs1;
    logic [4:0] hazard_rs2;

    assign hazard_rs1 = id_use_rs1 ? id_rs1 : 5'd0;
    assign hazard_rs2 = id_use_rs2 ? id_rs2 : 5'd0;

    hazard_unit u_hazard_unit (
        .idex_memread (ex_mem_read),
        .idex_rd      (ex_rd),
        .ifid_rs1     (hazard_rs1),
        .ifid_rs2     (hazard_rs2),
        .pc_write     (pc_write),
        .ifid_write   (ifid_write),
        .idex_flush   (idex_hazard_flush)
    );

    assign pc_debug   = wb_pc;
    assign instr_valid = wb_valid;

    logic _unused;
    assign _unused = ex_zero | mem_mem_to_reg | (|wb_instr) | (|mem_instr);
endmodule
