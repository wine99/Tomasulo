`timescale 1ns/1ps
`include "head.v"

module ReservationStation(
    input clk,
    input nRST,
    input EXEable, // whether the ALU is available and ins can be issued
    //����ALU��available����ʾ��ǰALU�Ƿ���ã���ALU�ǿ���״̬��ʱ�������־��1
    input WEN, // Write ENable ����CU��ResStationEN

    input [1:0] ResStationDst,// TODO:  ����վ�ı�ţ�alu����վ��01��mul����վ��10��ֱ�ӽӵغ͵�Դ
    //����վÿ����ı�ţ�ȫ�֣���ʽ�� ����վ��ţ�����վ�����
    input [2:0] opCode,   //����CU��ALUOp��ֱ�������opOut
    input [31:0] dataIn1,//����RF��DataOut1
    input [3:0] label1,//����RF��LabelOut1
    input [31:0] dataIn2,//����RF��DataOut2��Decoder��immd16��������չ��ɵ���ѡһ��·
    input [3:0] label2,//����RF��LabelOut2�͵صĶ�ѡһ��·

    input BCEN, // BroadCast ENable������CDB��EN�źţ�memory��pmfState, mfState������ֻҪ��һ�����ʹ��CDB������
    //BCEN����1
    input [3:0] BClabel, // BoradCast label  ����CDB��labelOut
    input [31:0] BCdata, //BroadCast value ����CDB��dataOut

    output [2:0] opOut,//����state��op������ALU��OP��ڣ���ǰָ��Ĳ����룬����ALU����ʲô����
    output [31:0] dataOut1,
    output [31:0] dataOut2,
    //����dataOut�����������������뵽ALU�����������������
    output isFull, // whether the buffer is full
    //���뵽CU��isFull��CU�������л�����������������alu����վ��0��mul����վ��1��һ��������2
    output OutEn, // whether output is valid�����뵽State��WEN���룬ָʾ����վ���Ƿ���ָ��׼����
    output [3:0] ready_labelOut,//�ӵ�ALU��labelIn�����䵱ǰ����ָ��ı���վ���
    output [3:0] writeable_labelOut//�ӵ�mux4to1_4��һ������
    //����ѡһ��ѡ��һ���źŵ�RF��WriteLabel��ѡ���ĸ���CU�����������źŷֱ�����һ�����к���������վ
    //����RF���������뵽�������ط������ܺͿ���RF��������й�
    );
//�ܹ�ֻ����������վ��mfALU�ĺ�pmfALU�ģ�
//ÿ������վ��������
    // 设置了三�?保留�?
    // 若使b2'11来索引，无效
    //busy��ָ���д������ʱ������Ϊ1����ָ�������ɺ�ָ�Ϊ0
    reg Busy[2:0];
    reg [1:0]Op[2:0];
    reg [3:0]Qj[2:0];
    reg [31:0]Vj[2:0];
    reg [3:0]Qk[2:0];
    reg [31:0]Vk[2:0];

    // 当前�?写地址 ,2'b11则为不可�???
    //��ʾ��ǰ���ŵ���
    reg [1:0] cur_addr ;
    // 当前就绪地址,2'b11则为不可�???
    //��ʾ�������������Ѿ�׼���ã���ʱ�����͸�ALU���м������
    reg [1:0] ready_addr ;
    initial begin
        Busy[0] = 0;
        Busy[1] = 0;
        Busy[2] = 0;
    end
    
    always@(posedge clk or negedge nRST) begin
        if (nRST == 0) begin 
            Busy[0] <= 0;
            Busy[1] <= 0;
            Busy[2] <= 0;
        end
        else begin 
            if (WEN == 1) begin
                if (cur_addr != 2'b11 && Busy[cur_addr] == 0) begin
                    Busy[cur_addr] <= 1;
                    Op[cur_addr] <= opCode;
                    if (BCEN == 1 & label1 == BClabel) begin
                        //tomauslo���Ĵ������������µ�ָ��д���ʱ���ȴ�CDB����һ��Դ�������Ĵ����ȴ��������Ƿ���
                        //CDB�ϣ��ڵĻ�����ֱ���ù���
                        Qj[cur_addr] <= 0;
                        Vj[cur_addr] <= BCdata;
                    end
                    else begin
                    //tomasulo���Ĵ���������CDBû�еĻ���ֱ�Ӱ�RF������Դ������ֵ��labelд��
                    //��ʱд���Դ������ֵ��������ȷ�ģ���ʱlabelӦ����0�����߻��ڼ��㣬��ʱlabel����0��
                    //�Ĵ�������֮�󣬱���վ�е���ͺ�RF�ֿ��ˣ����Vj��û׼���ã���Qj����ע��ȴ���label��
                    //��֮���clk������ʱ�򣬻��������watch CDB�ĵط��Ѽ������ֵд�룬����Ҫ�ٴ�RF���ȡ
                    //�����WAR��ͻ
                        Qj[cur_addr] <= label1;
                        Vj[cur_addr] <= dataIn1;
                    end
                    //Դ������2�Ĳ�����һ���ģ����Ǹ���ָ���ʽ��ͬԴ������2Ҳ��ͬ������label2���ܵ�ѡ���·���Ƶ�
                    if (BCEN == 1 && label2 == BClabel) begin
                        Qk[cur_addr] <= 0;
                        Vk[cur_addr] <= BCdata;
                    end
                    else begin
                        Qk[cur_addr] <= label2;
                        Vk[cur_addr] <= dataIn2;
                    end
                end
                //  maybe generate latch
            end
            // watch CDB
            //�����RAW��ͻ
            if (BCEN == 1 ) begin 
                if (BClabel[3:2] == ResStationDst) begin
                //ע��BClabel����Դ��BClabel������˼����ָ�����ڵı���վ����ı�ţ�
                //���Ե�һ��if�ǰѸ����busy����Ϊ0
                    Busy[BClabel[1:0]] <= 0; 
                end
                //������busy��1����ѵȴ�CDB�����ݵ�����и���
                if (Busy[0] == 1 && Qj[0] == BClabel) begin
                    Vj[0] = BCdata;
                    Qj[0] = 0;
                end
                if (Busy[1] == 1 && Qj[1] == BClabel) begin
                    Vj[1] = BCdata;
                    Qj[1] = 0;
                end
                if (Busy[2] == 1 && Qj[2] == BClabel) begin
                    Vj[2] = BCdata;
                    Qj[2] = 0;
                end
                if (Busy[0] == 1 && Qk[0] == BClabel) begin
                    Vk[0] = BCdata;
                    Qk[0] = 0;
                end
                if (Busy[1] == 1 && Qk[1] == BClabel) begin
                    Vk[1] = BCdata;
                    Qk[1] = 0;
                end
                if (Busy[2] == 1 && Qk[2] == BClabel) begin
                    Vk[2] = BCdata;
                    Qk[2] = 0;
                end
            end
        end
    end    
    

    assign opOut = Op[ready_addr];
    assign dataOut1 = Vj[ready_addr];
    assign dataOut2 = Vk[ready_addr];
    
    // 优先译码，使用组合�?�辑生成当前�?写地址
    // 若为2'b11则不�?�?
    //00�ű���վ������ȼ����
    always@(*) begin
        if (Busy[0] == 0) begin
            cur_addr = 2'b00;
        end
        else if (Busy[1] == 0) begin
            cur_addr = 2'b01;
        end
        else if (Busy[2] == 0) begin
            cur_addr = 2'b10;
        end
        else
            cur_addr = 2'b11;
    end

    // 保留站是否满
    //ֻ�е�cur_addr��11b��ʱ��&cur_addr����1
    assign isFull = & cur_addr;

    // �?否就�?
    // 计算当前就绪地址，以及就�?状�????
    //����������������׼���õ���
    //00������ȼ�����ߵ�
    always@(*)begin
        if (Busy[0] == 1 && Qj[0] == 0 && Qk[0] == 0) begin
            ready_addr = 2'b00;
        end
        else begin
            if(Busy[1] == 1 && Qj[1] == 0 && Qk[1] == 0) begin
                ready_addr = 2'b01;
            end
            else begin 
                if (Busy[2] == 1 && Qj[2] == 0 && Qk[2] == 0 ) begin
                    ready_addr = 2'b10;
                end
                else 
                    ready_addr = 2'b11;
            end
        end
    end

    //ֻ�е�ready_addr��11b��ʱ��outEn����0
    //Ҳ����ֻҪ����վ������׼�����ˣ���OutEn����1
    assign OutEn = ~ (&ready_addr);

    //ָ���ı���վ��׼���õı���վ���
    assign ready_labelOut = {ResStationDst,ready_addr};// TODO:
    //����ǰ���еı���վ�����������ALU�Ŀ����������RF��WriteLabel����Ϊ��һ��ָ��Ҫ����ı���վ��
    assign writeable_labelOut = {ResStationDst, cur_addr};

endmodule