`include "head.v"
`timescale 1ns/1ps
module CU(
    input [5:0] op,
    input [5:0] func,
    output reg[2:0]ALUop,
    output reg[1:0]ALUSel,
    output reg[3:0]ResStationEN,
    input [2:0]isFull,
    output isFullOut,
    output RegDst,
    output vkSrc,
    output QueueOp
);
    always@(*) begin
        case(op)
            `opRFormat:
                case(func)
                    `funcADD, `funcMULU:
                        ALUop = 0;  
                    `funcSUB : ALUop = `ALUSub;
                    `funcAND : ALUop = `ALUAnd;
                    `funcOR : ALUop = `ALUOr;
                    `funcXOR : ALUop = `ALUXor;
                    `funcNOR : ALUop = `ALUNor;
                    `funcSLT : ALUop = `ALUSlt;
                endcase
            `opADDI : ALUop = `ALUAdd;
            `opORI : ALUop = `ALUOr;
            `opANDI : ALUop = `ALUAnd;
            `opXORI : ALUop = `ALUAnd;
            `opSLTI : ALUop = `ALUSlt;
            default:
                ALUop = 1;
        endcase
        if (op == `opHALT) begin
        //ͣ��ָ�ALUsel��ɸ���̬����ֹPC������RF��ȡ
            ALUSel = 2'bz;
            ResStationEN = 4'b0000;
        end
        else if (op == `opRFormat && func == `funcMULU) begin
            ALUSel = `multipleALU;
            ResStationEN = 4'b0010;
        end
        else if (op == `opRFormat && func == `funcDIVU) begin
        //����ûʵ�֣����Գ���λ�õ�ALUsel��2'b11
            ALUSel = `divideALU;
            ResStationEN = 4'b0100;
        end 
        else if (op == `opLW || op == `opSW) begin
        //��ָ����SW����LW��ʱ��isFullOutӦ�����Queue��full���������ALUsel��2'b10��
            ALUSel = 2'b10;
            ResStationEN = 4'b1000;
        end else begin
            ALUSel = `addsubALU;
            ResStationEN = 4'b0001;
        end
    end
    //�Ѷ��кͱ���վ��full�ź����룬���ݵ�ǰָ������ĸ��������ͻظò�����full�źţ���full�ź�ȡ�������PC��
    //pcwrite������fullΪ1�Ļ�PCwrite��0��Ҳ����PC����������ʵ���������Ժ�������
    assign isFullOut = isFull[ALUSel];
    assign RegDst = op == `opRFormat ? `FromRd : `FromRt;
    assign vkSrc = op == `opRFormat ? `FromRtData : `FromImmd;
    assign QueueOp = op == `opLW ? `opLoad : `opStore;
endmodule    