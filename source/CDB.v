`timescale 1ns/1ps
`include "head.v"
module CDBHelper(
    input [3:0] requires,
    //cdbHelper��requires�ź�������ALU�����ݴ洢�ṩ��Ҳ����˵���requires�ź�Ӧ����
    //����׼���������Ժ���Ҫ��CDB��������ʱ�������ź�
    //����֮�����ж�requires[3]��֮����ж������ģ�����֪��requires[3]�����ȼ���ߵ�
    //Ҳ����memory�����ȼ���ߵģ���memory׼���������Ժ�����Ӧmemory��
    output reg [3:0] accepts
    //accepts��0����pmfstate��requireAC��1����mfState��3����memory
    //cdbHelper������ALU��memory���ܵ�require�ź�֮���ٰ�accepts�źŷ�������������
    //���accepts�źſ�����һ����Ӧ�źţ�����cdbHelper�Ĺ��ܾ��ǽ��յ������ķ�����������֮��
    //������Ӧ�źţ�����memory�����ȼ�����ߵģ������mfstate�������pmfState
);
//��ν��CDBHelper��ʵ���Ǹ����ȱ���������������������requires[3]��
//Ҳ����memory�����ȼ���ߵģ�һ���ò������Ҫʹ��CDB�������ݵ�����
//����Ӧ�ò�������ʹ��Ȩ������
    initial begin
        accepts = 4'b0000;
    end
    always@(*) begin
        if (requires[3])
            accepts = 4'b1000;
            //�������ϲ��룬�����accepts�źſ��ܱ�ʾ����CDB��ʹ��Ȩ��1��ʾ����ʹ�ã�0��ʾ����
        else if (requires[2])
            accepts = 4'b0100;
        else if (requires[1])
            accepts = 4'b0010;
        else if (requires[0])
            accepts = 4'b0001;
        else
            accepts = 4'b0000;
    end
endmodule

module CDB(
    input [31:0] data0,//�ӵ�pmfALU��result��
    input [3:0] label0,//�ӵ�pmfALU��labelOut��
    input [31:0] data1,//�ӵ�mfALU��result��
    input [3:0] label1,//�ӵ�mfALU��labelOut��
    input [31:0] data2,//�ӵ�
    input [3:0] label2,//�ӵ�
    input [31:0] data3,//�ӵ�memory��loadData����memory����������
    input [3:0] label3,//�ӵ�memory��labelOut�ϣ�memory��labelOutֱ�������Queue��labelOut
    input [3:0] sel,//0��pmfState, 1��mfState, 2:0, 3��memory���ӵ�������������require�ϣ���ʾ��CDB�������ź�
    //sel��cdbHelper��requires����������ͬһ����
    //cdbHelper������Ӧmemory������
    output reg[31:0] dataOut,
    //�ӵ�����������վ��BCdata��RF��BCdata������Queue��BCdata
    output reg[3:0] labelOut,
    //�ӵ�����������վ��BClabel��RF��BClabel������Queue��BClabel
    output EN
    //�ӵ�����������վ��BCEN��RF��BCEN������Queue��BCEN
);
//��������ȼ���֪��Ϊʲô�������cdbHelper���෴�ģ�
//����pmfState��memoryͬʱ���require=1��memory��requires[3]��pmfState��requires[0]
//��ô��cdbHelper�ﷵ�ص�accept�ź���1000��Ҳ���Ǹ�memory������ȷ���źţ�
//����������ȴ���ж�sel[0]��Ҳ����pmfState�ģ����Ұ�pmfState�����ݷŵ�CDB�ϣ�
//����������������memory������ȷ�ϣ�ȴ��pmfState�����ݷ���ȥ��
//����������д���˰ɡ�
    initial begin
        dataOut = 0;
        labelOut = 0;
    end
    always@(*) begin
        if (sel[3]) begin
            dataOut = data3;
            labelOut = label3;
        end else if (sel[2]) begin
            dataOut = data2;
            labelOut = label2;
        end else if (sel[1]) begin
            dataOut = data1;
            labelOut = label1;
        end else begin
            dataOut = data0;
            labelOut = label0;
        end
    end
    //����������û�����źţ�������require����0��ʱ��EN����0
    assign EN = | sel;
endmodule