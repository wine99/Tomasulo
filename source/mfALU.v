`timescale 1ns/1ps
`include "head.v"
module mfState(
    input clk,
    input nRST,
    output reg [2:0] stateOut, // ֻ�ӵ�ALU
    input WEN,//������mul����վ��OutEn����ʾ����վ������Ƿ���Ч
    //�ο�����վ����֪����ֻҪ����վ����һ��ָ�����������׼����ϣ���ָ����Լ�����
    //��ôOutEn�źž���1��ͬʱ����վ��Ѹ�ָ������
    //Ҳ����WENΪ1��ʱ���ʾ����վ��ָ��׼�����ˣ��Ѿ�׼�����
    input requireAC,//���ȱ�������Ӧ�źţ�CDBHelper���յ�CDB�����������ȼ����ظ��źţ�1��ʾ
    //MFALU������CDB��������
    output available,//���뵽����վ��EXEable�ź��ϣ���ʾ��ǰALU�Ƿ����ִ��/����
    output mfALUEN, // determine whether mdfALU should work
    //���뵽mf_alu��EN�ź���
    input [2:0] op, // do nothing������mul����վ��opOut���Ǳ���վ�б���������ALUָ��Ĳ�����
    output require  //CDB�����źţ���ALU�������֮�����ø��ź������ȱ���������CDBʹ��Ȩ
    //1��ʾ����
);
    //��ALU���ǿ���״̬����ô����CDB��������Ժ�ֻ�е�Ҳ���յ���CDB����Ӧ�ź��Ժ�ALU�����ǿ���
    //Ҳ����˵����ALU���ǿ���״̬����ô����û�����CDB������ʱ����ʱALU�������㣩��
    //����˶�CDB���������û���յ���Ӧʱ����ʱ���ڵȴ�CDB����Ӧ�źţ�
    //ALU������æµ��״̬��������
    //ֻҪstate��Idle����ôALU�ض����У��ض�����
    assign available = (require && requireAC) || stateOut == `sIdle;
    //mfALUEN���뵽��ALU��EN�ź��ϣ�EN��1��ʱ��ALU�ſ��Խ��м���
    //���������available��WENͬʱ��1��ʱ��ALU�ſ��Խ��м���
    //WENֻ�����˵�һ���ALU�ļ��㣬֮��ļ��㲻��ҪWEN����
    //�ڵ�һ��CLK�����Ժ�state��ӿ��б��Mul32����������̻�δ��������Ҫ���CLK��
    //���Դ�ʱ��available��0�������mfALUENҲ��0
    assign mfALUEN = available && WEN;
    //sMulAnswer���ܱ�ʾ����ALU������ϵ�״̬�������ڸ�״̬��ʱ��
    //require��1��Ҳ������Ҫ��CDB�������ݣ����������
    assign require = stateOut == `sMulAnswer;
    initial begin
        stateOut = `sIdle;
    end
    always@(posedge clk or negedge nRST) begin
        if (!nRST) begin
        //�����źţ���ALU��״̬���óɿ���
            stateOut <= `sIdle;
        end else begin
            case(stateOut)
                `sMulAnswer:
                //������ALU������ϵ�״̬��ʱ�򣬶��Ƿ���յ���CDB�ķ����źŽ����ж�
                //������յ��˷����źţ���ʾCDB�Ѿ������˼�������ALU��ȫ��������Ѿ���ϣ�
                //���Խ�����һ��ָ��ļ���
                //���ʱ���WEN�����жϣ��жϱ���վ���Ƿ���׼���õ�ָ�
                //����У���ô״̬�ı�ΪsMul32(���״̬�����Ǳ�ʾALU���ڼ��㣩
                //���û�У���ôALU�������״̬��
                //����û���յ�CDB�ķ����źŵ�ʱ��ɶҲ����
                    if (requireAC) begin
                        stateOut <= WEN ? `sMul32 : `sIdle;
                    end
                `sIdle:
                //��ALU�ǿ��е�״̬��ʱ�򣬶�WEN���м�⣬
                //�����1����ʾ����վ��ָ��׼�����ˣ���״̬�л������ڼ���
                    if (WEN)
                        stateOut <= `sMul32;
                default:
                    stateOut <= stateOut + 1;
            endcase
        end
    end
endmodule

module mfALU(
    input clk,
    input nRST,
    input EN, // linked from state::mfALUEN
    input [31:0] dataIn1,//����mul����վ��dataOut1����һ��������
    input [31:0] dataIn2,//����mul����վ��dataOut2���ڶ���������
    input [2:0] state,//����mfState��stateOut����ǰALU��״̬
    input [3:0] labelIn,//���Ա���վ��ready_labelOut���Ǳ���վ��׼���õ�ָ�����ڵ����
    output reg [31:0] result,
    output reg [3:0] labelOut //ֻҪENΪ1����������labelIn
    //labelOut��result���ӵ�CDB��
);
//�������г˷������ٶ������˷�
    reg [31:0]temp32[0:31];
    reg [31:0]temp16[0:15];
    reg [31:0]temp8[0:7];
    reg [31:0]temp4[0:3];
    reg [31:0]temp2[0:1];
    
    initial begin
        result = 0;
        labelOut = 0;
    end

    always@(posedge clk or negedge nRST) begin
        if (!nRST) begin
            labelOut <= 0;
        end else if (EN) begin
            labelOut <= labelIn;
        end
    end

//ע��generate���ص㣬������32�����еĲ���������ͬʱ���м���
//���Ե�һ��ֻ��Ҫһ��clk�Ϳ��԰�temp32��32����������
//����ÿ��CLK����һ�㣬�ܹ���Ҫ���CLK�Ϳ��Լ����������˷�
//���⣬�ڵ�һ��CLK��ȥ�Ժ�EN�źŻ����㣬����֮��ļ�����̲�����EN������
    generate
        genvar i;  
        for (i = 0; i <= 31; i=i+1) begin
            always@(posedge clk or negedge nRST) begin
                if (!nRST) begin
                    temp32[i] <= 32'b0;
                end else if (EN) begin
                    temp32[i] <= dataIn2[i] == 0 ? 0 : dataIn1 << i;
                    //����dataIn2��ÿλ�ǲ���0����dataIn1���ƶ�Ӧλ��������ֵ��temp32��32���Ĵ���
                end
            end
        end

        for (i = 0; i <= 15; i=i+1) begin
            always@(posedge clk or negedge nRST) begin
                if (!nRST) begin
                    temp16[i] <= 32'b0;
                end else begin
                    temp16[i] <= temp32[i] + temp32[i + 16];
                end
            end
        end

        for (i = 0; i <= 7; i=i+1) begin
            always@(posedge clk or negedge nRST) begin
                if (!nRST) begin
                    temp8[i] <= 32'b0;
                end else begin
                    temp8[i] <= temp16[i] + temp16[i + 8];
                end
            end
        end

        for (i = 0; i <= 3; i=i+1) begin
            always@(posedge clk or negedge nRST) begin
                if (!nRST) begin
                    temp4[i] <= 32'b0;
                end else begin
                    temp4[i] <= temp8[i] + temp8[i + 4];
                end
            end
        end
    endgenerate
    always@(posedge clk or negedge nRST) begin
        if (!nRST) begin
            temp2[0] <= 32'b0;
            temp2[1] <= 32'b0;
            result <= 32'b0;
        end else begin
            temp2[0] <= temp4[0] + temp4[2];
            temp2[1] <= temp4[1] + temp4[3];
            result <= temp2[0] + temp2[1];
        end
    end
endmodule