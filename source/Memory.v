`timescale 1ns/1ps

module Memory(
    input clk,
    input WEN,
    input [31:0] dataIn1,// Qj
    input [31:0] dataIn2,// A 
    input op,// for example, 1 is load, 0 is write����д�����ź�
    input [31:0] writeData,  //Ҫ��洢��д�������
    input [3:0] labelIn,
    output reg [3:0] labelOut, //���뵽CDB��label�����ϣ�Ӧ���Ǳ���վ���������1100����
    output [31:0] loadData,  //�Ӵ洢����ȡ������
    output reg available,   //�����Ǳ�ʾ��ǰmemory�Ƿ����
    output reg require,   //CDB�����źţ�������׼����Ϻ���Ҫʹ��CDB��������
    //���źŽ��������ȱ�����cdbHelper
    input requireAC,  //�Ƿ����ʹ��CDB�������ݣ�����CDBHelper���ȱ�������1��ʾ����
    output isLastState
);
//memory��ͨ����RAM���ʵ�ֵģ�������ʵ����һ����ȡ��д����ʱ����10�����ڵĴ洢��
//Ŀǰ��һ���Ի�����Ϊʲôд��ĵ�ַ�������dataIn1��dataIn2�ĺ�
//���ǽ���ʵ�ֵ�ʱ�����ڿ��Բ��ÿ��Ǵ洢���Ķ�ȡ��д����ʱ�����Կ��Բ���ʵ�ֵ���ô����
    reg [31:0] addr;
    reg nRD;
    reg nWR;
    integer States;
    initial begin
        States = 0;
        nRD = 1;
        nWR = 1;
        require = 0;
    end 
    wire readStatus;
    wire writeStatus;
    always@( posedge clk ) begin
        if (States == 0) begin
            if (WEN == 1) begin
            //������0״̬������ʹ���ź������ʱ��׼���õ�ַ
            //������״̬1�����Ѵ��ݸ�RAM��д�Ͷ������ź����ú�
            //���ʱ��RAM��clk���½��ؿ�ʼ��ͻῪʼ��ȡ/д�룬������Ҫ10������׼����
                addr <= dataIn1 + dataIn2;
                labelOut <= labelIn;
                States <= 1;
            // States �?0 变成1，进入访存阶�?
                if (op == 1) begin
                    nRD <= 0;
                end
                if (op == 0) begin
                    nWR <= 0;
                end
            end
            else begin // WEN == 0
                States <= 0;
                nRD <= 1;
                nWR <= 1;
            end
        end
        else if (States == 1) begin
        //����״̬1��ʱ��RAM���ڽ��ж�ȡ/д���������ʱÿ��һ��clk�ж��Ƿ�д��/��ȡ���
                nRD <= 1;
                nWR <= 1;
                if (readStatus == 1) begin
                //����ȡ��ϵ�ʱ��
                //�л���״̬2��������CDB���ȱ��������ʹ��CDB������
                    States <= 2;
                    require <= 1;
                end
                if (writeStatus == 1) begin
                //��д����ϵ�ʱ�򣬲���Ҫ��CDB�������
                //״̬���0���ȴ���һ��д����ȡ
                    require <= 0;
                    States <= 0;
                end
            end
        else if (States == 2) begin
        //��״̬2��ʱ�򣬵ȴ����ȱ��������ص���Ӧ�ź�
        //����Ӧ�ź���1����ʾCDB���������ݣ�����˵CDB�Ѿ��õ�������
        //�޸�״̬Ϊ0���ȴ���һ�ζ�ȡ/д��
            if (requireAC == 1) begin
                States <= 0;
            end
            else begin
            //�������CDB��û׼���ã���һֱ����״̬2
                States <= 2;
            end
        end
        else 
            States <= 4;
            //�����ļ���û��˵����״̬4��ʱ��Ӧ����ʲô
            //�������״̬4���ܲ��ᵽ���ʵûɶ��
    end

    always@(*) begin
        if (States == 1 || States == 2) begin
        //��״̬1��ʱ�����ڶ�ȡ/д����ʹ�����Դ�ʱmemory���ڲ�����״̬
        //��״̬2��ʱ���ȡ�����ݻ�û�͵�CDB�ϣ����Դ�ʱmemoryҲ�ǲ�����״̬
            available = 0;
        end
        else begin
            available = 1; //TODO :maybe bugs not a good implementation
        end
    end

    RAM my_ram(
        .clk(clk),
        .address(addr),
        .writeData(writeData),
        .Dataout(loadData),
        .readStatus(readStatus),
        .writeStatus(writeStatus),
        .nRD(nRD),
        .nWR(nWR),
        .isLastState(isLastState)
    );

endmodule