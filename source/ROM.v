`timescale 1ns/1ps
module ROM (  
    input nrd, //�������нӵ���
    output reg [31:0] dataOut,
    input [31:0] addr//�ӵ�PC�����
    ); 

    reg [7:0] rom [0:99]; 
    initial begin 
         //$readmemb ("E:/myfile/�������ϵ�ṹ/����/Tomasulo-master/rom/mytest.mem", rom);
         rom[0] = 8'b00100000;
         rom[1] = 8'b00000001;
         rom[2] = 8'b00000000;
         rom[3] = 8'b00000001;
         
         rom[4] = 8'b00100000;
         rom[5] = 8'b00000001;
         rom[6] = 8'b00000000;
         rom[7] = 8'b00000001;
         
         rom[8] = 8'b00100000;
         rom[9] = 8'b00000001;
         rom[10] = 8'b00000000;
         rom[11] = 8'b00000001;
         
         rom[12] = 8'b11111100;
         rom[13] = 8'b00000000;
         rom[14] = 8'b00000000;
         rom[15] = 8'b00000000;
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