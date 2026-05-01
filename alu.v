`timescale 1ns / 1ps
//*************************************************************************
//   > 文件名: alu.v
//   > 描述  ：ALU模块，可做16种操作
//   > 作者  : 白星炜、饶甜甜、王仁刚、任墨涵
//   > 日期  : 2025-03-06
//*************************************************************************
module alu(
    input  [15:0] alu_control,  // ALU控制信号
    input  [31:0] alu_src1,     // ALU操作数1,为补码
    input  [31:0] alu_src2,     // ALU操作数2，为补码
    output [31:0] alu_result    // ALU结果
    );

    // ALU控制信号，独热码
    wire alu_add;   //加法操作
    wire alu_sub;   //减法操作
    wire alu_slt;   //有符号比较，小于置位，复用加法器做减法
    wire alu_sltu;  //无符号比较，小于置位，复用加法器做减法
    wire alu_and;   //按位与
    wire alu_nor;   //按位或非
    wire alu_or;    //按位或
    wire alu_xor;   //按位异或
    wire alu_sll;   //逻辑左移
    wire alu_srl;   //逻辑右移
    wire alu_sra;   //算术右移
    wire alu_lui;   //高位加载
    wire alu_mul;   //有符号乘法操作
    wire alu_div;   //有符号除法操作
    wire alu_mulu;   //无符号乘法操作
    wire alu_divu;   //无符号除法操作

    assign alu_divu = alu_control[15];    //无符号除法操作
    assign alu_mulu = alu_control[14];    //无符号乘法操作
    assign alu_div  = alu_control[13];    //有符号除法操作
    assign alu_mul  = alu_control[12];    //有符号乘法操作
    assign alu_add  = alu_control[11];
    assign alu_sub  = alu_control[10];
    assign alu_slt  = alu_control[ 9];
    assign alu_sltu = alu_control[ 8];
    assign alu_and  = alu_control[ 7];
    assign alu_nor  = alu_control[ 6];
    assign alu_or   = alu_control[ 5];
    assign alu_xor  = alu_control[ 4];
    assign alu_sll  = alu_control[ 3];
    assign alu_srl  = alu_control[ 2];
    assign alu_sra  = alu_control[ 1];
    assign alu_lui  = alu_control[ 0];

    wire [31:0] add_sub_result;
    wire [31:0] slt_result;
    wire [31:0] sltu_result;
    wire [31:0] and_result;
    wire [31:0] nor_result;
    wire [31:0] or_result;
    wire [31:0] xor_result;
    wire [31:0] sll_result;
    wire [31:0] srl_result;
    wire [31:0] sra_result;
    wire [31:0] lui_result;
    wire [31:0] mul_result;     //有符号乘法结果
    wire [31:0] div_result;     //有符号除法结果
    wire [31:0] mul_resultu;     //无符号乘法结果
    wire [31:0] div_resultu;     //无符号除法结果

    assign and_result = alu_src1 & alu_src2;      // 与结果为两数按位与
    assign or_result  = alu_src1 | alu_src2;      // 或结果为两数按位或
    assign nor_result = ~or_result;               // 或非结果为或结果按位取反
    assign xor_result = alu_src1 ^ alu_src2;      // 异或结果为两数按位异或
    assign lui_result = {alu_src2[15:0], 16'd0};  // 立即数装载结果为立即数移位至高半字节

//-----{加法器}begin
//add,sub,slt,sltu均使用该模块
    wire [31:0] adder_operand1;
    wire [31:0] adder_operand2;
    wire        adder_cin     ;
    wire [31:0] adder_result  ;
    wire        adder_cout    ;
    assign adder_operand1 = alu_src1; 
    assign adder_operand2 = alu_add ? alu_src2 : ~alu_src2; 
    assign adder_cin      = ~alu_add; //减法需要cin 
    adder adder_module(               //实例化adder.v中的加法器
    .operand1(adder_operand1),
    .operand2(adder_operand2),
    .cin     (adder_cin     ),
    .result  (adder_result  ),
    .cout    (adder_cout    )
    );

    //加减结果
    assign add_sub_result = adder_result;

    //slt结果
    //adder_src1[31] adder_src2[31] adder_result[31]
    //       0             1           X(0或1)       "正-负"，显然小于不成立
    //       0             0             1           相减为负，说明小于
    //       0             0             0           相减为正，说明不小于
    //       1             1             1           相减为负，说明小于
    //       1             1             0           相减为正，说明不小于
    //       1             0           X(0或1)       "负-正"，显然小于成立
    assign slt_result[31:1] = 31'd0;
    assign slt_result[0]    = (alu_src1[31] & ~alu_src2[31]) | (~(alu_src1[31]^alu_src2[31]) & adder_result[31]);

    //sltu结果
    //对于32位无符号数比较，相当于33位有符号数（{1'b0,src1}和{1'b0,src2}）的比较，最高位0为符号位
    //故，可以用33位加法器来比较大小，需要对{1'b0,src2}取反,即需要{1'b0,src1}+{1'b1,~src2}+cin
    //但此处用的为32位加法器，只做了运算:                             src1   +    ~src2   +cin
    //32位加法的结果为{adder_cout,adder_result},则33位加法结果应该为{adder_cout+1'b1,adder_result}
    //对比slt结果注释，知道，此时判断大小属于第二三种情况，即源操作数1符号位为0，源操作数2符号位为0
    //结果的符号位为1，说明小于，即adder_cout+1'b1为2'b01，即adder_cout为0
    assign sltu_result = {31'd0, ~adder_cout};
//-----{加法器}end

//-----{移位器}begin
    // 移位分三步进行，
    // 第一步根据移位量低2位即[1:0]位做第一次移位，
    // 第二步在第一次移位基础上根据移位量[3:2]位做第二次移位，
    // 第三步在第二次移位基础上根据移位量[4]位做第三次移位。
    wire [4:0] shf;
    assign shf = alu_src1[4:0];
    wire [1:0] shf_1_0;
    wire [1:0] shf_3_2;
    assign shf_1_0 = shf[1:0];
    assign shf_3_2 = shf[3:2];
    
     // 逻辑左移
    wire [31:0] sll_step1;
    wire [31:0] sll_step2;
    assign sll_step1 = {32{shf_1_0 == 2'b00}} & alu_src2                   // 若shf[1:0]="00",不移位
                     | {32{shf_1_0 == 2'b01}} & {alu_src2[30:0], 1'd0}     // 若shf[1:0]="01",左移1位
                     | {32{shf_1_0 == 2'b10}} & {alu_src2[29:0], 2'd0}     // 若shf[1:0]="10",左移2位
                     | {32{shf_1_0 == 2'b11}} & {alu_src2[28:0], 3'd0};    // 若shf[1:0]="11",左移3位
    assign sll_step2 = {32{shf_3_2 == 2'b00}} & sll_step1                  // 若shf[3:2]="00",不移位
                     | {32{shf_3_2 == 2'b01}} & {sll_step1[27:0], 4'd0}    // 若shf[3:2]="01",第一次移位结果左移4位
                     | {32{shf_3_2 == 2'b10}} & {sll_step1[23:0], 8'd0}    // 若shf[3:2]="10",第一次移位结果左移8位
                     | {32{shf_3_2 == 2'b11}} & {sll_step1[19:0], 12'd0};  // 若shf[3:2]="11",第一次移位结果左移12位
    assign sll_result = shf[4] ? {sll_step2[15:0], 16'd0} : sll_step2;     // 若shf[4]="1",第二次移位结果左移16位

    // 逻辑右移
    wire [31:0] srl_step1;
    wire [31:0] srl_step2;
    assign srl_step1 = {32{shf_1_0 == 2'b00}} & alu_src2                   // 若shf[1:0]="00",不移位
                     | {32{shf_1_0 == 2'b01}} & {1'd0, alu_src2[31:1]}     // 若shf[1:0]="01",右移1位,高位补0
                     | {32{shf_1_0 == 2'b10}} & {2'd0, alu_src2[31:2]}     // 若shf[1:0]="10",右移2位,高位补0
                     | {32{shf_1_0 == 2'b11}} & {3'd0, alu_src2[31:3]};    // 若shf[1:0]="11",右移3位,高位补0
    assign srl_step2 = {32{shf_3_2 == 2'b00}} & srl_step1                  // 若shf[3:2]="00",不移位
                     | {32{shf_3_2 == 2'b01}} & {4'd0, srl_step1[31:4]}    // 若shf[3:2]="01",第一次移位结果右移4位,高位补0
                     | {32{shf_3_2 == 2'b10}} & {8'd0, srl_step1[31:8]}    // 若shf[3:2]="10",第一次移位结果右移8位,高位补0
                     | {32{shf_3_2 == 2'b11}} & {12'd0, srl_step1[31:12]}; // 若shf[3:2]="11",第一次移位结果右移12位,高位补0
    assign srl_result = shf[4] ? {16'd0, srl_step2[31:16]} : srl_step2;    // 若shf[4]="1",第二次移位结果右移16位,高位补0
 
    // 算术右移
    wire [31:0] sra_step1;
    wire [31:0] sra_step2;
    assign sra_step1 = {32{shf_1_0 == 2'b00}} & alu_src2                                 // 若shf[1:0]="00",不移位
                     | {32{shf_1_0 == 2'b01}} & {alu_src2[31], alu_src2[31:1]}           // 若shf[1:0]="01",右移1位,高位补符号位
                     | {32{shf_1_0 == 2'b10}} & {{2{alu_src2[31]}}, alu_src2[31:2]}      // 若shf[1:0]="10",右移2位,高位补符号位
                     | {32{shf_1_0 == 2'b11}} & {{3{alu_src2[31]}}, alu_src2[31:3]};     // 若shf[1:0]="11",右移3位,高位补符号位
    assign sra_step2 = {32{shf_3_2 == 2'b00}} & sra_step1                                // 若shf[3:2]="00",不移位
                     | {32{shf_3_2 == 2'b01}} & {{4{sra_step1[31]}}, sra_step1[31:4]}    // 若shf[3:2]="01",第一次移位结果右移4位,高位补符号位
                     | {32{shf_3_2 == 2'b10}} & {{8{sra_step1[31]}}, sra_step1[31:8]}    // 若shf[3:2]="10",第一次移位结果右移8位,高位补符号位
                     | {32{shf_3_2 == 2'b11}} & {{12{sra_step1[31]}}, sra_step1[31:12]}; // 若shf[3:2]="11",第一次移位结果右移12位,高位补符号位
    assign sra_result = shf[4] ? {{16{sra_step2[31]}}, sra_step2[31:16]} : sra_step2;    // 若shf[4]="1",第二次移位结果右移16位,高位补符号位
//-----{移位器}end


// 有符号乘法器
reg [63:0] product;  // 64位部分积
reg [31:0] multiplicand;  // 被乘数
reg extra_bit;  // 额外位，跟踪前一位
integer i;
always @(*) begin
    product = {32'b0, alu_src2};  // 初始化：高32位为0，低32位为乘数
    multiplicand = alu_src1;
    extra_bit = 1'b0;  // 额外位初始为0
    for (i = 0; i < 32; i = i + 1) begin
        case ({product[0], extra_bit})  // 检查当前LSB和额外位
            2'b00: ;  // 无操作
            2'b01: product[63:32] = product[63:32] + multiplicand;  // 加被乘数
            2'b10: product[63:32] = product[63:32] - multiplicand;  // 减被乘数
            2'b11: ;  // 无操作
        endcase
        extra_bit = product[0];  // 更新额外位
        product = $signed(product) >>> 1;  // 算术右移
    end
end
assign mul_result = product[31:0];  // 取低32位



// 有符号除法器：基于逐位恢复法
reg [31:0] dividend_abs;
reg [31:0] divisor_abs;
reg [31:0] quotient_signed;
reg [31:0] remainder_signed;
reg        sign_q;    // 商的符号：1 表示负数
reg signed [31:0] signed_dividend;
reg signed [31:0] signed_divisor;
integer j;

// 定义一个寄存器存放最终有符号除法结果
reg [31:0] div_result_reg;
assign div_result = div_result_reg;

always @(*) begin
    // 将输入转换为有符号数
    signed_dividend = $signed(alu_src1);
    signed_divisor  = $signed(alu_src2);
    
    // 1. 确定商的符号：仅当被除数与除数符号不同时，结果为负
    sign_q = (signed_dividend < 0) ^ (signed_divisor < 0);
    
    // 2. 计算被除数和除数的绝对值
    dividend_abs = (signed_dividend < 0) ? (~signed_dividend + 1) : signed_dividend;
    divisor_abs  = (signed_divisor  < 0) ? (~signed_divisor  + 1) : signed_divisor;
    
    // 3. 除数为0时，返回全1（可根据系统需求调整异常处理）
    if (divisor_abs == 0) begin
        quotient_signed = 32'hFFFFFFFF;
        remainder_signed = 32'b0;
    end else begin
        quotient_signed = 0;
        remainder_signed = 0;
        // 4. 逐位恢复法：从最高位（j=31）到最低位（j=0）
        for (j = 31; j >= 0; j = j - 1) begin
            // 将余数左移1位，并将 dividend_abs 的第 j 位送入余数的最低位
            remainder_signed = {remainder_signed[30:0], dividend_abs[j]};
            // 如果当前余数大于或等于除数，则减去除数并将当前商位置为1
            if (remainder_signed >= divisor_abs) begin
                remainder_signed = remainder_signed - divisor_abs;
                quotient_signed[j] = 1'b1;
            end else begin
                quotient_signed[j] = 1'b0;
            end
        end
    end
    
    // 5. 根据符号调整商：若 sign_q 为1，则对商取补码
    if (sign_q)
        quotient_signed = ~quotient_signed + 1;
    
    // 保存最终结果
    div_result_reg = quotient_signed;
end

// 无符号乘法器
reg [63:0] productu;      // 64位部分积
integer k;
always @(*) begin
    // 初始化：高32位为0，低32位为乘数（无符号）
    productu = {32'b0, alu_src2};
    // 迭代32次，每次处理乘数的一位
    for (k = 0; k < 32; k = k + 1) begin
        // 如果当前最低位为1，则加上乘数
        if (productu[0] == 1'b1) begin
            productu[63:32] = productu[63:32] + alu_src1;
        end
        // 逻辑右移1位（不保留符号）
        productu = productu >> 1;
    end
end
assign mul_resultu = productu[31:0];  // 取低32位作为乘法结果

// 无符号除法器
reg [63:0] rem_quot;     // 64位寄存器，存储余数（高32位）和商（低32位）
reg [31:0] divisoru;      // 除数（无符号）
integer p;
always @(*) begin
    divisoru = alu_src2;  // 直接使用除数（无符号）
    // 除数为0时，返回全1
    if (divisoru == 32'b0) begin
        rem_quot = 64'hFFFF_FFFF_FFFF_FFFF;
    end
    else begin
        // 初始化：余数置0，被除数放入低32位
        rem_quot = {32'b0, alu_src1};
        // 迭代32次，每次左移1位并更新余数和商
        for (p = 0; p < 32; p = p + 1) begin
            // 左移1位，低位补0
            rem_quot = {rem_quot[62:0], 1'b0};
            // 如果余数部分（高32位）大于或等于除数，则减除数并置商位为1
            if (rem_quot[63:32] >= divisoru) begin
                rem_quot[63:32] = rem_quot[63:32] - divisoru;
                rem_quot[0] = 1'b1;
            end
            else begin
                rem_quot[0] = 1'b0;
            end
        end
    end
end
assign div_resultu = rem_quot[31:0];  // 商在低32位

    // 选择相应结果输出
    assign alu_result = alu_divu          ? div_resultu : 
                        alu_mulu          ? mul_resultu :
                        alu_div           ? div_result :
                        alu_mul           ? mul_result :
                        (alu_add|alu_sub) ? add_sub_result[31:0] : 
                        alu_slt           ? slt_result :
                        alu_sltu          ? sltu_result:
                        alu_and           ? and_result :
                        alu_nor           ? nor_result :
                        alu_or            ? or_result  :
                        alu_xor           ? xor_result :
                        alu_sll           ? sll_result :
                        alu_srl           ? srl_result :
                        alu_sra           ? sra_result :
                        alu_lui           ? lui_result :
                        32'd0;
endmodule
