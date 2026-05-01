`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Target Device:  
// Tool versions:  
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 改进的ALU测试文件，更全面地测试所有功能
// 
////////////////////////////////////////////////////////////////////////////////

module tb;

    reg   [15:0] alu_control;
    reg   [31:0] alu_src1;   
    reg   [31:0] alu_src2;   
    wire  [31:0] alu_result; 
    
    // 用于存储预期结果和测试名称
    reg   [31:0] expected_result;
    reg   [64*8:1] test_name;
    integer test_number = 0;
    
    // 实例化ALU模块
    alu alu_module(
        .alu_control(alu_control),
        .alu_src1   (alu_src1   ),
        .alu_src2   (alu_src2   ),
        .alu_result (alu_result )
    );
    
    // 验证结果的任务
    task verify_result;
    begin
        #2; // 等待结果稳定
        test_number = test_number + 1;
        if (alu_result === expected_result)
            $display("Test %0d (%0s): PASSED", test_number, test_name);
        else
            $display("Test %0d (%0s): FAILED. Expected: %h, Got: %h", 
                     test_number, test_name, expected_result, alu_result);
    end
    endtask

    initial begin
        // 初始化
        alu_control = 16'b0;
        alu_src1 = 32'b0;
        alu_src2 = 32'b0;
        expected_result = 32'b0;
        
        #5; // 初始稳定延时
        
        //======================== 加法操作测试 ========================
        test_name = "加法-正数";
        alu_control = 16'b0000_1000_0000_0000; // ADD
        alu_src1 = 32'd10086;
        alu_src2 = 32'd9900;
        expected_result = 32'd19986;
        verify_result();
        
        #5;
        test_name = "加法-负数";
        alu_control = 16'b0000_1000_0000_0000; // ADD
        alu_src1 = 32'hFFFFFFFF; // -1
        alu_src2 = 32'hFFFFFFFE; // -2
        expected_result = 32'hFFFFFFFD; // -3
        verify_result();
        
        #5;
        test_name = "加法-溢出";
        alu_control = 16'b0000_1000_0000_0000; // ADD
        alu_src1 = 32'h7FFFFFFF; // 最大正数
        alu_src2 = 32'd1;
        expected_result = 32'h80000000; // 变成负数（溢出）
        verify_result();
        
        //======================== 减法操作测试 ========================
        #5;
        test_name = "减法-正数";
        alu_control = 16'b0000_0100_0000_0000; // SUB
        alu_src1 = 32'd100;
        alu_src2 = 32'd50;
        expected_result = 32'd50;
        verify_result();
        
        #5;
        test_name = "减法-负结果";
        alu_control = 16'b0000_0100_0000_0000; // SUB
        alu_src1 = 32'd1;
        alu_src2 = 32'd2;
        expected_result = 32'hFFFFFFFF; // -1
        verify_result();
        
        #5;
        test_name = "减法-溢出";
        alu_control = 16'b0000_0100_0000_0000; // SUB
        alu_src1 = 32'h80000000; // 最小负数
        alu_src2 = 32'd1;
        expected_result = 32'h7FFFFFFF; // 变成正数（溢出）
        verify_result();
        
        //======================== 有符号比较测试 ========================
        #5;
        test_name = "有符号比较-小于为真";
        alu_control = 16'b0000_0010_0000_0000; // SLT
        alu_src1 = 32'd1;
        alu_src2 = 32'd2;
        expected_result = 32'd1; // 1 < 2，结果为真
        verify_result();
        
        #5;
        test_name = "有符号比较-大于为假";
        alu_control = 16'b0000_0010_0000_0000; // SLT
        alu_src1 = 32'd100;
        alu_src2 = 32'd50;
        expected_result = 32'd0; // 100 > 50，结果为假
        verify_result();
        
        #5;
        test_name = "有符号比较-负数小于正数";
        alu_control = 16'b0000_0010_0000_0000; // SLT
        alu_src1 = 32'hFFFFFFFF; // -1
        alu_src2 = 32'd1;        // 1
        expected_result = 32'd1; // -1 < 1，结果为真
        verify_result();
        
        //======================== 无符号比较测试 ========================
        #5;
        test_name = "无符号比较-小于为真";
        alu_control = 16'b0000_0001_0000_0000; // SLTU
        alu_src1 = 32'd5;
        alu_src2 = 32'd10;
        expected_result = 32'd1; // 5 < 10，结果为真
        verify_result();
        
        #5;
        test_name = "无符号比较-大于为假";
        alu_control = 16'b0000_0001_0000_0000; // SLTU
        alu_src1 = 32'd5;
        alu_src2 = 32'd2;
        expected_result = 32'd0; // 5 > 2，结果为假
        verify_result();
        
        #5;
        test_name = "无符号比较-负数视为大数";
        alu_control = 16'b0000_0001_0000_0000; // SLTU
        alu_src1 = 32'd5;
        alu_src2 = 32'hFFFFFFFF; // 作为无符号数是最大值
        expected_result = 32'd1; // 5 < 4294967295，结果为真
        verify_result();
        
        //======================== 按位与测试 ========================
        #5;
        test_name = "按位与";
        alu_control = 16'b0000_0000_1000_0000; // AND
        alu_src1 = 32'h12345678;
        alu_src2 = 32'hF0F0F0F0;
        expected_result = 32'h10305070;
        verify_result();
        
        //======================== 按位或非测试 ========================
        #5;
        test_name = "按位或非";
        alu_control = 16'b0000_0000_0100_0000; // NOR
        alu_src1 = 32'h0000000F;
        alu_src2 = 32'h00000001;
        expected_result = 32'hFFFFFFF0; // ~(0xF | 0x1)
        verify_result();
        
        //======================== 按位或测试 ========================
        #5;
        test_name = "按位或";
        alu_control = 16'b0000_0000_0010_0000; // OR
        alu_src1 = 32'h0000000E;
        alu_src2 = 32'h00000001;
        expected_result = 32'h0000000F;
        verify_result();
        
        //======================== 按位异或测试 ========================
        #5;
        test_name = "按位异或";
        alu_control = 16'b0000_0000_0001_0000; // XOR
        alu_src1 = 32'h0000000A; // 1010
        alu_src2 = 32'h00000005; // 0101
        expected_result = 32'h0000000F; // 1111
        verify_result();
        
        //======================== 逻辑左移测试 ========================
        #5;
        test_name = "逻辑左移-小量移位";
        alu_control = 16'b0000_0000_0000_1000; // SLL
        alu_src1 = 32'd4; // 移位4位
        alu_src2 = 32'hF; // 0xF
        expected_result = 32'hF0; // 0xF << 4 = 0xF0
        verify_result();
        
        #5;
        test_name = "逻辑左移-零位移位";
        alu_control = 16'b0000_0000_0000_1000; // SLL
        alu_src1 = 32'd0; // 移位0位
        alu_src2 = 32'hABCDEF01;
        expected_result = 32'hABCDEF01; // 不变
        verify_result();
        
        #5;
        test_name = "逻辑左移-大量移位";
        alu_control = 16'b0000_0000_0000_1000; // SLL
        alu_src1 = 32'd24; // 移位24位
        alu_src2 = 32'hFF; // 0xFF
        expected_result = 32'hFF000000; // 0xFF << 24
        verify_result();
        
        //======================== 逻辑右移测试 ========================
        #5;
        test_name = "逻辑右移-小量移位";
        alu_control = 16'b0000_0000_0000_0100; // SRL
        alu_src1 = 32'd4; // 移位4位
        alu_src2 = 32'hF0; // 0xF0
        expected_result = 32'h0F; // 0xF0 >> 4 = 0x0F
        verify_result();
        
        #5;
        test_name = "逻辑右移-大量移位";
        alu_control = 16'b0000_0000_0000_0100; // SRL
        alu_src1 = 32'd28; // 移位28位
        alu_src2 = 32'hF0000000;
        expected_result = 32'h0000000F; // 0xF0000000 >> 28 = 0x0000000F
        verify_result();
        
        //======================== 算术右移测试 ========================        
        #5;
        test_name = "算术右移-正数";
        alu_control = 16'b0000_0000_0000_0010; // SRA
        alu_src1 = 32'd4; // 移位4位
        alu_src2 = 32'h000000F0; // 正数
        expected_result = 32'h0000000F; // 结果同逻辑右移
        verify_result();
        
        #5;
        test_name = "算术右移-负数";
        alu_control = 16'b0000_0000_0000_0010; // SRA
        alu_src1 = 32'd4; // 移位4位
        alu_src2 = 32'hF0000000; // 负数
        expected_result = 32'hFF000000; // 高位补1
        verify_result();
        
        #5;
        test_name = "算术右移-负数大量移位";
        alu_control = 16'b0000_0000_0000_0010; // SRA
        alu_src1 = 32'd28; // 移位28位
        alu_src2 = 32'hF0000000; // 负数
        expected_result = 32'hFFFFFFFF; // 全部为1
        verify_result();
        
        //======================== 高位加载测试 ======================== 
        #5;
        test_name = "高位加载";
        alu_control = 16'b0000_0000_0000_0001; // LUI
        alu_src2 = 32'h0000BFC0;
        expected_result = 32'hBFC00000; // 低16位移到高16位，低16位补0
        verify_result();
        
        //======================== 有符号乘法测试 ========================
        #5;
        test_name = "有符号乘法-正数乘正数";
        alu_control = 16'b0001_0000_0000_0000; // MUL  
        alu_src1 = 32'd3;  
        alu_src2 = 32'd4;  
        expected_result = 32'd12; // 3 * 4 = 12
        verify_result();
        
        #5;
        test_name = "有符号乘法-负数乘负数";
        alu_control = 16'b0001_0000_0000_0000;  
        alu_src1 = 32'hFFFFFFD8; // -40
        alu_src2 = 32'hFFFFFFF8; // -8
        expected_result = 32'd320; // -40 * -8 = 320
        verify_result();
        
        #5;
        test_name = "有符号乘法-正数乘负数";
        alu_control = 16'b0001_0000_0000_0000;  
        alu_src1 = 32'd4;   // 4
        alu_src2 = 32'hFFFFFFF8; // -8
        expected_result = 32'hFFFFFFE0; // 4 * -8 = -32
        verify_result();
        
        //======================== 无符号乘法测试 ========================
        #5;
        test_name = "无符号乘法-正数";
        alu_control = 16'b0100_0000_0000_0000; // MULU
        alu_src1 = 32'd10;
        alu_src2 = 32'd20;
        expected_result = 32'd200; // 10 * 20 = 200
        verify_result();
        
        #5;
        test_name = "无符号乘法-大数";
        alu_control = 16'b0100_0000_0000_0000; // MULU
        alu_src1 = 32'hF0000000; // 解释为大正数
        alu_src2 = 32'd2;
        expected_result = 32'hE0000000; // 由于溢出，只保留低32位
        verify_result();
        
        //======================== 有符号除法测试 ========================
        #5;
        test_name = "有符号除法-正除正";
        alu_control = 16'b0010_0000_0000_0000; // DIV  
        alu_src1 = 32'd16;  // 被除数
        alu_src2 = 32'd4;   // 除数
        expected_result = 32'd4; // 16 / 4 = 4
        verify_result();
        
        #5;
        test_name = "有符号除法-负除负";
        alu_control = 16'b0010_0000_0000_0000;  
        alu_src1 = 32'hFFFFFFD8; // -40
        alu_src2 = 32'hFFFFFFF8; // -8
        expected_result = 32'd5; // -40 / -8 = 5
        verify_result();
        
        #5;
        test_name = "有符号除法-负除正";
        alu_control = 16'b0010_0000_0000_0000;  
        alu_src1 = 32'hFFFFFFF0; // -16
        alu_src2 = 32'd4;        // 4
        expected_result = 32'hFFFFFFFC; // -16 / 4 = -4
        verify_result();
        
        #5;
        test_name = "有符号除法-除以0";
        alu_control = 16'b0010_0000_0000_0000;  
        alu_src1 = 32'd16;  // 被除数
        alu_src2 = 32'd0;   // 除数为0
        expected_result = 32'hFFFFFFFF; // 错误结果，全1
        verify_result();
        
        #5;
        test_name = "有符号除法-最小负数除以-1";
        alu_control = 16'b0010_0000_0000_0000;
        alu_src1 = 32'h80000000; // -2³¹
        alu_src2 = 32'hFFFFFFFF; // -1
        expected_result = 32'h80000000; // 保持原值（特殊情况）
        verify_result();
        
        //======================== 无符号除法测试 ========================
        #5;
        test_name = "无符号除法-标准情况";
        alu_control = 16'b1000_0000_0000_0000; // DIVU
        alu_src1 = 32'd100;
        alu_src2 = 32'd10;
        expected_result = 32'd10; // 100 / 10 = 10
        verify_result();
        
        #5;
        test_name = "无符号除法-除以0";
        alu_control = 16'b1000_0000_0000_0000; // DIVU
        alu_src1 = 32'd100;
        alu_src2 = 32'd0;
        expected_result = 32'hFFFFFFFF; // 错误结果，全1
        verify_result();
        
        #5;
        test_name = "无符号除法-负数视为大正数";
        alu_control = 16'b1000_0000_0000_0000; // DIVU
        alu_src1 = 32'hFFFFFFFF; // 4294967295（无符号）
        alu_src2 = 32'd2;
        expected_result = 32'h7FFFFFFF; // 4294967295 / 2 = 2147483647
        verify_result();
        
        // 测试结束
        #5;
        $display("ALU测试完成，共执行%0d个测试", test_number);
        $finish;
    end
endmodule