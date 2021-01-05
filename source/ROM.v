`timescale 1ns/1ps
module ROM (  
    input nrd, //在例子中接地了
    output reg [31:0] dataOut,
    input [31:0] addr//接到PC的输出
    ); 

    reg [7:0] rom [0:99]; 
    initial begin 
        //$readmemb ("C:/Users/Administrator/Desktop/workplace/Tomasulo/rom/rom.mem", rom); 
         $readmemb ("F:/code/git/Tomasulo/rom/rom.mem", rom);   //ROM的初始化
       // $readmemb ("E:/code/Tomasulo/rom/testcase6.mem", rom); 
//         $readmemb ("C:/Users/Administrator/Desktop/workplace/Tomasulo/rom/testcase5.mem", rom);
        // $readmemb ("C:/Users/Administrator/Desktop/workplace/Tomasulo/rom/rom.mem", rom); 
    end
    always @(*) begin
        if (nrd == 0) begin
            dataOut[31:24] = rom[addr];      //rom定义了100个8位存储，但是32位地址也还可以寻址
            dataOut[23:16] = rom[addr+1];
            dataOut[15:8] = rom[addr+2];
            dataOut[7:0] = rom[addr+3];
        end else begin
            dataOut[31:0] = {32{1'bz}};      //32个随机信号
        end
    end
endmodule