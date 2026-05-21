`timescale 1ns / 1ps

module alu(
    input        [31 : 0] A,
    input        [31 : 0] B,
    input        [3  : 0] aluop,
    output logic [31 : 0] alures,
    output logic          ZF,
    output logic          OF
);

    localparam	AND   =	4'b0000;
	localparam	OR    =	4'b0001;
	localparam	XOR   =	4'b0010;
	localparam	NAND  =	4'b0011;
	localparam	NOT   =	4'b0100;
	localparam	SLL   =	4'b0101;
	localparam	SRL   =	4'b0110;
	localparam	SRA   =	4'b0111;
	localparam	MULU  =	4'b1000;
	localparam	MUL   =	4'b1001;
	localparam	ADD   =	4'b1010;
	localparam	ADDU  =	4'b1011;
	localparam	SUB   =	4'b1100;
	localparam	SUBU  =	4'b1101;
	localparam	SLT   =	4'b1110;
	localparam	SLTU  =	4'b1111;
	
	// TODO: Finish the ALU_32bits design！！！
	// 内部信号
    logic [31:0] alu_result;
    logic [63:0] mulu_result, mul_result;
    logic [31:0] B_sel;          // 选择B或~B
    logic Cin_sel;               // 选择进位输入
    logic [31:0] add_sub_result; // 加减法结果
    logic carry_out;             // 加法器进位输出
    logic add_sub_overflow;      // 加减法溢出标志
    logic slt_result, sltu_result;
    
    // 加减法操作数选择
    assign B_sel = (aluop == SUB || aluop == SUBU) ? ~B : B;
    assign Cin_sel = (aluop == SUB || aluop == SUBU) ? 1'b1 : 1'b0;
    
    // 行波进位加法器实例
    rca adder(
        .A(A),
        .B(B_sel),
        .Cin(Cin_sel),
        .S(add_sub_result),
        .Cout(carry_out)
    );
    
    // 乘法运算
    assign mulu_result = A * B;                    // 无符号乘法
    assign mul_result = $signed(A) * $signed(B);   // 有符号乘法
    
    // 溢出判断逻辑
    always_comb begin
        if (aluop == ADD || aluop == SUB) begin
            // 加减法溢出判断：操作数符号相同且与结果符号不同
            add_sub_overflow = (A[31] == B_sel[31]) && (add_sub_result[31] != A[31]);
        end else begin
            add_sub_overflow = 1'b0;
        end
    end
    
    // 比较运算
    assign slt_result = ($signed(A) < $signed(B)) ? 1'b1 : 1'b0;
    assign sltu_result = (A < B) ? 1'b1 : 1'b0;
    
    // ALU操作选择
    always_comb begin
        alu_result = 32'b0;
        OF = 1'b0;
        
        case(aluop)
            AND:  alu_result = A & B;
            OR:   alu_result = A | B;
            XOR:  alu_result = A ^ B;
            NAND: alu_result = ~(A & B);
            NOT:  alu_result = ~A;
            SLL:  alu_result = A << B[4:0];
            SRL:  alu_result = A >> B[4:0];
            SRA:  alu_result = $signed(A) >>> B[4:0];
            MULU: alu_result = mulu_result[31:0];
            MUL:  alu_result = mul_result[31:0];
            ADD:  begin 
                alu_result = add_sub_result; 
                OF = add_sub_overflow; 
            end
            ADDU: alu_result = add_sub_result;
            SUB:  begin 
                alu_result = add_sub_result; 
                OF = add_sub_overflow; 
            end
            SUBU: alu_result = add_sub_result;
            SLT:  alu_result = {31'b0, slt_result};
            SLTU: alu_result = {31'b0, sltu_result};
            default: alu_result = 32'b0;
        endcase
    end
    
    assign alures = alu_result;
    
    // 零标志
    assign ZF = (alu_result == 32'b0);

endmodule
