
`timescale 1ns / 1ps
//*************************************************************************
//   > 文件名: adder.v
//   > 描述  ：32位超前进位加法器（Carry-Lookahead Adder）
//   > 作者  : 白星炜
//   > 日期  : 2025-03-02
//*************************************************************************
module adder (
    input  [31:0] operand1,  // 加数1
    input  [31:0] operand2,  // 加数2
    input         cin,       // 进位输入
    output [31:0] result,    // 和结果
    output        cout       // 进位输出
);

    // 定义每4位一组的进位信号
    wire [7:0] carry;  // 每组之间的进位，carry[0]为最低组的进位输出
    assign carry[0] = cin;  // 最低位进位来自外部输入cin

    // 定义每组的G和P信号
    wire [7:0] G_group;  // 每组的进位产生信号
    wire [7:0] P_group;  // 每组的进位传递信号

    // 实例化8个4位CLA模块
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : cla_block
            cla_4bit cla_inst (
                .a(operand1[4*i+3 : 4*i]),   // 每组4位输入A
                .b(operand2[4*i+3 : 4*i]),   // 每组4位输入B
                .cin(carry[i]),              // 每组的进位输入
                .sum(result[4*i+3 : 4*i]),   // 每组的和输出
                .G(G_group[i]),              // 组进位产生信号
                .P(P_group[i])               // 组进位传递信号
            );
            // 计算下一组的进位
            if (i < 7) begin
                assign carry[i+1] = G_group[i] | (P_group[i] & carry[i]);
            end
        end
    endgenerate

    // 最高位进位输出
    assign cout = G_group[7] | (P_group[7] & carry[7]);

endmodule

// 4位超前进位加法器子模块
module cla_4bit (
    input  [3:0] a,    // 4位输入A
    input  [3:0] b,    // 4位输入B
    input        cin,  // 进位输入
    output [3:0] sum,  // 4位和输出
    output       G,    // 组进位产生信号
    output       P     // 组进位传递信号
);
    wire [3:0] g;  // 每位的进位产生信号
    wire [3:0] p;  // 每位的进位传递信号
    wire [4:1] c;  // 内部进位信号（c[1]到c[4]，c[0]为cin）

    // 计算每位的G和P
    assign g = a & b;         // G[i] = A[i] & B[i]
    assign p = a | b;         // P[i] = A[i] | B[i]

    // 计算内部进位
    assign c[1] = g[0] | (p[0] & cin);        // C1 = G0 + P0·Cin
    assign c[2] = g[1] | (p[1] & c[1]);       // C2 = G1 + P1·C1
    assign c[3] = g[2] | (p[2] & c[2]);       // C3 = G2 + P2·C2
    assign c[4] = g[3] | (p[3] & c[3]);       // C4 = G3 + P3·C3

    // 计算和
    assign sum[0] = a[0] ^ b[0] ^ cin;        // S0 = A0 ^ B0 ^ Cin
    assign sum[1] = a[1] ^ b[1] ^ c[1];       // S1 = A1 ^ B1 ^ C1
    assign sum[2] = a[2] ^ b[2] ^ c[2];       // S2 = A2 ^ B2 ^ C2
    assign sum[3] = a[3] ^ b[3] ^ c[3];       // S3 = A3 ^ B3 ^ C3

    // 计算组的G和P
    assign G = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign P = p[0] & p[1] & p[2] & p[3];

endmodule