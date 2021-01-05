`timescale 1ns/1ps
module ROM (  
    input nrd, //�������нӵ���
    output reg [31:0] dataOut,
    input [31:0] addr//�ӵ�PC�����
    ); 

    reg [7:0] rom [0:99]; 
    initial begin 
        //$readmemb ("C:/Users/Administrator/Desktop/workplace/Tomasulo/rom/rom.mem", rom); 
         $readmemb ("F:/code/git/Tomasulo/rom/rom.mem", rom);   //ROM�ĳ�ʼ��
       // $readmemb ("E:/code/Tomasulo/rom/testcase6.mem", rom); 
//         $readmemb ("C:/Users/Administrator/Desktop/workplace/Tomasulo/rom/testcase5.mem", rom);
        // $readmemb ("C:/Users/Administrator/Desktop/workplace/Tomasulo/rom/rom.mem", rom); 
    end
    always @(*) begin
        if (nrd == 0) begin
            dataOut[31:24] = rom[addr];      //rom������100��8λ�洢������32λ��ַҲ������Ѱַ
            dataOut[23:16] = rom[addr+1];
            dataOut[15:8] = rom[addr+2];
            dataOut[7:0] = rom[addr+3];
        end else begin
            dataOut[31:0] = {32{1'bz}};      //32������ź�
        end
    end
endmodule