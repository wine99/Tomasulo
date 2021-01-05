`timescale 1ns / 1ps
`include "head.v"
module PC(
    input clk,
    input nRST,
    input [31:0]newpc,
    input pcWrite,//��ִ�е���ͣ��ָ���ʱ��pcWriteΪ0
    //��һ�������ǵ�ǰִ�е�ָ����Ҫ�Ĳ���������վ�����У��Ƿ����ˣ�������ˣ�pcWriteҲ��0
    output reg [31:0]pc
    );
    initial begin
        pc = 0;
    end
    always@(posedge clk or negedge nRST) begin
        if (pcWrite || !nRST) begin
            pc <= nRST == 0 ? 0 : newpc;             //pc��ֵ����д���������
        end else begin
            pc <= pc;
        end
    end
endmodule

module PCHelper(
    input [31:0] pc,
    input [15:0] immd16,
    input [25:0] immd26,
    input [1:0] sel,//�������нӵ��ˣ�����ÿ�θ��²��� ����PC+4
    input [31:0] rs,
    output reg [31:0] newpc
    );
    //ͨ����CU�����������һ��PC������ֵ
    initial begin
        newpc = 0;
    end
    wire [31:0]exd_immd16 = { {16{immd16[15]}}, immd16};      //������չ
    always@(*) begin
        case (sel)
            `NextIns : newpc <= pc + 4;
            `RelJmp : newpc <= (pc + 4 + (exd_immd16 << 2));
            `AbsJmp : newpc <= {pc[31:28], immd26, 2'b00};
            `RsJmp : newpc <= rs;
        endcase
    end
endmodule
