// Lab 3, variant 3: observe RV32I ADD in the MAX configuration.
// Simulation-only observer; it does not change the processor.
module scr1_tb_log_cmd (
    input logic        clk,
    input logic        rst_n,
    input logic        id_accept,
    input logic [31:0] id_instr,
    input logic        ex_retire,
    input logic        ex_exception,
    input logic [31:0] curr_pc,
    input logic [31:0] rs1_value,
    input logic [31:0] rs2_value,
    input logic [31:0] rd_value
);
    logic [31:0] ex_instr;
    wire [6:0] opcode = ex_instr[6:0];
    wire [4:0] rd     = ex_instr[11:7];
    wire [2:0] funct3 = ex_instr[14:12];
    wire [4:0] rs1    = ex_instr[19:15];
    wire [4:0] rs2    = ex_instr[24:20];
    wire [6:0] funct7 = ex_instr[31:25];

    // funct7 is essential: SUB and MUL share ADD's opcode and funct3.
    wire is_add = (opcode == 7'b0110011)
               && (funct3 == 3'b000)
               && (funct7 == 7'b0000000);
    wire add_retire = rst_n && ex_retire && !ex_exception && is_add;

    // Mirror the instruction register on the SAME handshake as the EXU queue.
    // On a stall keep the instruction; ex_retire prevents repeated messages.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_instr <= 32'b0;
        end else begin
            if (id_accept)
                ex_instr <= id_instr;
            if (add_retire) begin
                $display("ADD pc=%08h instr=%08h opcode=%02h funct3=%01h funct7=%02h rd=x%0d rs1=x%0d rs2=x%0d rs1_value=%08h rs2_value=%08h result=%08h",
                         curr_pc, ex_instr, opcode, funct3, funct7,
                         rd, rs1, rs2, rs1_value, rs2_value, rd_value);
            end
        end
    end
endmodule
