`timescale 1ns / 1ps
`include "head.v"
module RegFile(
    input clk,
    input nRST,
    input [4:0] ReadAddr1,//����ָ���rs
    input [4:0] ReadAddr2,//����rt
    input RegWr, //labelEN���ߵ�ƽ��Ч������CU��isFullOut
    input [4:0] WriteAddr, //����ָ���rt����rd
    input [3:0] WriteLabel,//������ѡһ����������վ��writeable_labelOut��Queue��һ�������ѡһ��
    //�ڱ���վ�и��źű�ʾ�˵�ǰ����վ�п��ŵ����label
    input [5:0] op,
    output [31:0] DataOut1,
    output [31:0] DataOut2,
    output [3:0] LabelOut1,
    output [3:0] LabelOut2,
    input BCEN,
    input [3:0] BClabel,
    input [31:0] BCdata
    );
    reg [31:0] regData[1:31];
    reg [3:0] regLabel[1:31];
    assign DataOut1 = (ReadAddr1 == 0) ? 0 : regData[ReadAddr1];   //0�żĴ���ֵʼ����0
    assign DataOut2 = (ReadAddr2 == 0) ? 0 : regData[ReadAddr2];   //����������߼�
    assign LabelOut1 = (ReadAddr1 == 0) ? 0 : regLabel[ReadAddr1];
    assign LabelOut2 = (ReadAddr2 == 0) ? 0 : regLabel[ReadAddr2];
    generate
        genvar i;
        for (i = 1; i < 32; i = i + 1) begin: regfile
            always @(posedge clk or negedge nRST) begin    //д����ʱ���߼�
                if (!nRST) begin
                    regData[i] <= 32'b0;               //дgenerate��Ŀ�ģ�����Ҫ�ԼĴ���ˢ�µ�ʱ������õ�ѭ��
                    regLabel[i] <= 32'b0;
                end else begin
                    if (RegWr && WriteAddr == i) begin
                        if (op != `opSW)begin
                        //swָ���Ҫд��Ĵ���ֵ
                            regLabel[i] <= WriteLabel; // don't care whether WriteLabel is the same as BClabel. 
                            // Anyway, it is overriden by WriteLabel at last.
                        end
                            //tomasulo��һ�����裬ָ�������Ժ��Ҫд��Ŀ��Ĵ������ϸ�ָ���ڱ���վ�еı��
                            //�����WAW��ͻ
                            //�������еļĴ�����ʹ���ź�Ϊ1����Ҫд����ǵ�ǰ�ļĴ�����ʱ��
                            //�ѱ�־д�룬��־����Ҫд��üĴ����ı���վ���
                            //writeLabel���Ա���վ�е�ǰ���ŵı���վ��label��Ҳ���Ǹ�������˵�ǰ��ָ��
                    end else if (BCEN && regLabel[i] == BClabel) begin
                            //BClabel(broadcast label)������˼���ı���վ��ţ�
                            //��CDB����
                            //�������еļĴ�������־���ڸñ���վ��ŵļĴ������ݸ���
                            //ͬʱ��־�����ʾ�Ĵ������ݼ������
                        regLabel[i] <= 5'b0;
                        regData[i] <= BCdata;
                    end
                end
            end
        end
    endgenerate
endmodule