`timescale 1ns/1ps
`include "head.v"
module pmfState(
    input clk,
    input nRST,
    output reg [1:0] stateOut,//����pmfALU��״̬
    input WEN, //����alu����վ��OutEn��������վ�ڴ���ָ��׼����������1
    input requireAC, //CDB��Ӧ�źţ���cdbHelper���أ�Ϊ1��ʱ���ʾCDB�Ѿ�����������
    output available,//��ǰALU�Ƿ���ã����뵽alu����վ��EXEable
    output pmfALUEN, // send to pmfALU as EN
    input [2:0]op,//���Ա���վ��opOut��׼����ϵ�ָ��Ĳ�����
    output require //CDB�����źţ���ALU������Ϻ������ȱ�����cdbHelper��������
);
    //��mfALUһ��
    assign available = (require && requireAC) || stateOut == `sIdle;
    assign pmfALUEN = available && WEN;
    //������������״̬��ʱ���ʾ������ϣ���CDBHelper������ҪCDB������
    assign require = stateOut == `sPremitiveIns || stateOut == `sMAdd;
    initial begin
        stateOut = `sIdle;
    end
    //sPremitiveIns��ʾ�ӷ�������ϣ���pmfALU�У��������Ǽӷ�����״̬����idle��ʱ���һ������
    //���Ѿ��ѽ����������ˣ�������ڵ�ʱ��pmfstate�Ű�״̬�л���sPremitiveIns�����������״̬��ʱ�����ֱ�ӷ���CDB���롣
    //�����м��������ʱ�򣬵�һ��clk ALU����Ļ���idle״̬���Ѳ��������룬���ʱ���������ûȡ��
    //pmfState�ڵ�һ��clk��״̬�л���inverse���ڵڶ���clk��ALU�Ѳ�����ȡ�������õ���������
    //pmfState��״̬���Madd����ʾ����������ϲ���CDB����������CDBһֱû��Ӧ����ôÿ��clk
    //ALU��pmfstateɶ�����ɣ�ֱ�����˻�Ӧ��pmfState��״̬���idle
    always@(posedge clk or negedge nRST) begin
        if (!nRST) begin
            stateOut <= `sIdle;
        end else begin
            case (stateOut)
                `sIdle : 
                    if (WEN)
                    //����ǰ�ǿ���״̬���ж�WEN���������վ��׼���õ�ָ�
                    //����ݸ�ָ��Ĳ������״̬��ֵ���Ա���֮����Ƽ���
                        stateOut <= op == `ALUSub ? `sInverse : `sPremitiveIns;
                `sPremitiveIns, `sMAdd : begin
                //������������״̬��ʱ���ʾ������ϣ�
                //�����յ���CDB�Ļ�Ӧ�źţ����״̬���óɿ���
                    if (requireAC) begin
                        // if (WEN) begin
                            // stateOut <= op == `ALUSub ? `sInverse : `sPremitiveIns;
                        // end else begin
                            stateOut <= `sIdle;
                        // end
                    end
                end
                `sInverse:
                    stateOut <= `sMAdd;
            endcase
        end
    end
endmodule

module pmfALU(
    input clk,
    input nRST,
    input EN, // linked from State::pmfALUEN
    input [31:0] dataIn1,//���Ա���վ����һ��������
    input [31:0] dataIn2,//���Ա���վ���ڶ���������
    input [1:0] state,//����pmfState������ALU��״̬
    input [2:0]op,//���Ա���վ��opOut����ǰִ��ָ��Ĳ�����
    output reg [31:0] result,//�͵�CDB��data0
    input [3:0] labelIn,//���Ա���վ��ready_labelOut����ǰָ���ڱ���վ�еı��
    output reg [3:0] labelOut//�͵�CDB��label0
);
    reg [31:0] data1_latch;
    reg [31:0] data2_latch;
    reg [31:0] inverseData2_latch;
    reg [2:0] op_latch;
    initial begin
        result = 0;
        labelOut = 0;
    end
    always@(posedge clk or negedge nRST) begin
        if (!nRST) begin
            data1_latch <= 32'b0;
            data2_latch <= 32'b0;
            inverseData2_latch <= 31'b0;
        end else begin
            if (EN)
                op_latch <= op;
            case (state)
                `sIdle, `sPremitiveIns, `sMAdd :
                    if (EN) begin
                        data1_latch <= dataIn1;
                        data2_latch <= dataIn2;
                        labelOut <= labelIn;
                    end
                `sInverse :
                    inverseData2_latch <= ~data2_latch + 1;
            endcase
        end
    end

    always@(*) begin
        case (op_latch)
            `ALUAdd : 
                result = data1_latch + data2_latch;
            `ALUSub : 
                result = data1_latch + inverseData2_latch;   //����ת���ɼӷ���ת����ȡ����һ
            `ALUAnd :
                result = data1_latch & data2_latch;
            `ALUOr:
                result = data1_latch | data2_latch;   
            `ALUXor:
                result = data1_latch ^ data2_latch;
            `ALUNor:
                result = ~ (data1_latch | data2_latch);
            `ALUSlt:
                result = data1_latch < data2_latch ? 1 : 0;
            default:
                result = 32'b0;
        endcase
    end
endmodule
