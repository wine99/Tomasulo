`timescale 1ns/1ps
`include "head.v"
// implement as queue.
module Queue(
    input clk,
    input nRST,
    input requireAC, // whether the ALU is available and ins can be issued������memory��avaible�ź�
    //��ʾ��ǰmemory�ܲ���ʹ�ã�����memory��д��Ҫ��ʱ������Ҫ����ʱ�����˲�����
    input WEN, // Write ENable������CU��ResStationEN������Queue�����뵽���źŵĵ�3����Ϊ1��ʱ���ʾ��Ҫ�����µ�ָ��
    output isFull, // whether the buffer is full��ֻ��RT���и��źŽ��뵽CU��isFull��2���±꣬���������ж�û��
    output require, // whether output is valid������������ɵ�2:0�źž���һ���������뵽memory��WEN��
    //��ʾ�Ƿ����������Ҫissue��Ҳ����ֻ�е��������ж���������Ҫissue��ʱ��memory�ſ��Կ�ʼ����

    input [31:0] dataIn,//�������е�dataIn����ĵط�������ͬ
    input [3:0] labelIn,//�������еĸ��źŽ���ĵط�Ҳ��һ����Immdֱ�ӽӵ���
    input opIN,//�������еĸ��źŶ����뵽��CU��QueueOp�ϣ�֮������źŻ��͸�opOut��
    //����CU��QueueOpӦ���Ƕ�д�����ź�

    input BCEN, // BroadCast ENable���ӵ�CDB��EN��
    input [3:0] BClabel, // BoradCast label���ӵ�CDB��labelOut��
    input [31:0] BCdata, //BroadCast value���ӵ�CDB��dataOut��

    output opOut,//ֻ��RT���еĸ��źŽ��뵽��memory��op�ϣ����ƶ�д���ߵ�ƽ�����͵�ƽд
    output [31:0] dataOut,//�������еĸ�����ֱ���뵽memory��dataIn1��dataIn2��writeData��
    //dataIn1��dataIn2֮�Ϳ��ƶ�д�ĵ�ַ
    output [3:0] labelOut,//ֻ��RT���е�labelOut�ӵ���memory��labelIn�ϣ�
    //memoryֱ�Ӱ�label�����CDB��Ӧ����1100���ֵı���վ���
    input isLastState,//����memory��isLastState���ڶ�ȡ��д����ʱ�����һ��������Ϊ1
    output [3:0] queue_writeable_label//ֻ��RT���еĸ��źŽ��뵽����ѡһ��һ������ϣ�
    //���źźͱ���վ��writeable_labelOut��ͬ���Ӧ�ã�������1100���ֵı���վ���
    );
    //storeָ���ִ�б�����˳��ģ�ԭ��������ж��storeָ���Ҫ��֤ͬһ����ַ�Ľ�������һ��storeָ��������
    //���Դ洢����վʹ���˶�����ʵ�֣��Ƚ����ָ����ִ��
    //���ڴ�PC��RF������������������߼������������ڱ���վ֮ǰȫ����˳��������
    //˳��������ָ���ڶ����б�����������˳��
    //����dataout�������dataֻ���Ƕ�ͷָ�������
    
    //�������п��õ���һ��
    reg [3:0]availableIdLabel;
    //���õ�Queue��ţ���Queueʵ���ж��е���ź�ʵ�ʵ��±겻��ͳһ�ģ����ֻ��һ���߼��ϵģ�ר����IdLabel��Queue���
    assign queue_writeable_label = availableIdLabel;
    //�������Ƿ����
    reg [3:0]Busy;
    //label�ǲ���ָ����RS��������label������RF
    reg [3:0]Label[3:0];
    //data��RS������
    reg [31:0]Data[3:0];
    //idlabel�ǵ�ǰ���ݴ���Queue���ĸ�label�ϣ���label���߼��ϵ�label���������±겻һһ��Ӧ
    reg [3:0]IdLabel[3:0];
    reg [3:0]op;
    initial begin
        Label[3] = 0;
        Busy[3] = 4'b1000;//Busy[3] = 0
        Data[3] = 0;
        IdLabel[3] = 0;
        op[3] = 0;
    end
    assign opOut = op[0];
    assign dataOut = Data[0];
    assign labelOut =IdLabel[0];

    //��ʾ�Ƿ�������������Ҫ���������memory���õ�ʱ��ſ������
    wire issuable = require && requireAC;
    //��ʾ�Ƿ�������ȫ����
    wire wbusy = Busy[0] && Busy[1] && Busy[2]; //��λ����������
    //��������ȫ���˲��Ҳ���������ʱ����full״̬
    //!issuable��Ϊ!popable
    assign isFull = !poppable && wbusy;
    //require��ʾ�Ƿ����������Ҫissue��0����busy�������Ѿ�׼���õĻ��Ϳ��������
    assign require = Busy[0] && Label[0] == 0;
    wire poppable;
    //��memory����ʱ����ֻʣ��һ��clk�Ϳ�����ɵ�ʱ�򣬶��п���pop
    //��ʱ��ͷ��ָ���Ѿ���ִ�����ˣ�������Queue�ڵ�����ָ�����������
    assign poppable = isLastState;
    
    reg [1:0] first_empty;
    always@(*) begin
        if (!Busy[0]) first_empty = 0;
        else if (!Busy[1]) first_empty = 1;
        else first_empty = 2;
    end

    reg [1:0]lastBusyIndex;
    always@(*) begin
        if (Busy[2])
            lastBusyIndex = 2;
        else if (Busy[1])
            lastBusyIndex = 1;
        else if (Busy[0])
            lastBusyIndex = 0;
        else lastBusyIndex = -1;
    end

    //Ѱ�ҿ��õĶ������
    always@(*) begin
        if (wbusy) 
        //������æ��ʱ��û�������ʹ��
            availableIdLabel = 4'bx; // if busy, it is don't-care signal
        else if (IdLabel[0] != `QUE0 && IdLabel[1] != `QUE0 && IdLabel[2] != `QUE0)
        //���������if(wbusy)���������Ȼ������һ�����busy�ģ�����busy�ĸ��º�idLabel��ͬ���ģ�
        //���Ա�Ȼ�����������һ������ǿ���ʹ�õģ����Դ�ʱavailableIdLabel��Ȼ���Եõ�����ʹ�õ����
            availableIdLabel = `QUE0;
        else if (IdLabel[0] != `QUE1 && IdLabel[1] != `QUE1 && IdLabel[2] != `QUE1)
            availableIdLabel = `QUE1;
        else availableIdLabel = `QUE2;
    end

    generate
        genvar i;
        for (i = 0; i <= 2; i = i + 1) begin
            always@(posedge clk or negedge nRST) begin
                if (!nRST) begin
                    Busy[i] <= 0;
                    Label[i] <= 0;
                    Data[i] <= 0;
                    IdLabel[i] <= 0;
                    op[i] <= 0;
                end else if (WEN) begin
                //WENΪ1�ͱ���վ���WEN��1��˼��һ���ģ���������һ��clk�����ذ���һ�������ָ���
                    if (!poppable) begin
                    //popable˵����ͷָ���Ƿ��Ѿ���ȡ���������Ե���
                    //����Ҫ������ָ�WEN=1�����Ҷ�ͷָ�ûִ���겻�ܵ�����!popable)
                    //���û��ȫ�������ڶ�β��first_empty)����һ����ָ��
                    //���ȫ���ˣ����ڲ��ܵ��������Կ�ס�ˣ������˽ṹ��ͻ��ֻ�ܸ��¸�����
                        if (!wbusy && i == first_empty) begin //Wen && !issuable && !busy
                            // input data to the first empty position
                            
                            Busy[i] <= 1;
                            //����RS���У����CDB��������ָ�����Դ���������ǿ��������Ϊ��Դ��������
                            //����Ϊ�Ĵ����������Դ������
                            Data[i] <= BCEN && BClabel==labelIn ? BCdata : dataIn;
                            Label[i] <= BCEN && BClabel == labelIn ? 0 : labelIn;
                            op[i] <= opIN;
                            IdLabel[i] <= availableIdLabel;
                        end else begin
                            if (BCEN && BClabel == Label[i]) begin // else watch for bc
                                Data[i] <= BCdata;
                                Label[i] <= 0;
                            end
                        end 
                    end else begin
                    //����ͷָ���Ѿ�ִ������Ե�����popable=1����
                    //�ض����Զ�����ָ��
                    //����ָ��ǰ��һλ�����һ��busy��λ�ö�����ָ��
                        if (i == lastBusyIndex) begin // WEN && issuable : queue must be available
                            // Busy is also 1, so do not change
                            Data[i] <= BCEN && BClabel == labelIn ? BCdata : dataIn;
                            Label[i] <= BCEN && BClabel ==  labelIn ? 0 : labelIn;
                            op[i] <= opIN;
                            IdLabel[i] <= availableIdLabel;
                        end else if (i < lastBusyIndex) begin // queue::pop()
                            Data[i] <= BCEN && BClabel == Label[i+1]? BCdata : Data[i+1];
                            Label[i] <= BCEN && BClabel == Label[i+1] ? 0 : Label[i+1];
                            op[i] <= op[i+1];
                            IdLabel[i] <= IdLabel[i+1];
                        end
                    end
                end else begin
                //WENΪ0��Ҳ���ǲ���Ҫ�����µ�ָ���ʱ��
                    if (poppable) begin
                    //������Ҫ������ָ�WEN=0�������ҿ��Ե�����ͷָ��ʱ
                    //����ָ��ǰ��һλ�����һ��busy��ָ����գ���Ϊ����Ҫ������ָ�
                        if (i == lastBusyIndex) begin //!Wen && issuable
                            Busy[i] <= 0;
                            Data[i] <= 0;
                            Label[i] <= 0;
                            op[i] <= 0;
                            IdLabel[i] <= 0;
                        end else if (i < lastBusyIndex) begin
                            Busy[i] <= Busy[i+1];
                            Data[i] <= BCEN && BClabel == Label[i+1] ? BCdata : Data[i+1];
                            Label[i] <= BCEN && BClabel ==  Label[i+1] ? 0 : Label[i+1];
                            op[i] <= op[i+1];
                            IdLabel[i] <= IdLabel[i+1];
                        end
                    end else begin //!WEN && !issuable
                    //����ͷָ���ִ����ʱ��!popable)
                    //�Ȳ���Ҫ����ָ�Ҳ����Ҫ������ͷָ���ʱ��
                    //ֻ��Ҫ���������ݸ���һ��
                        if (BCEN && BClabel == Label[i]) begin
                            Data[i] <= BCdata;
                            Label[i] <= 0;
                        end
                    end
                end
            end
        end
    endgenerate
endmodule