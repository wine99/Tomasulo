`timescale 1ns/1ps
`include "head.v"
// implement as queue.
module Queue(
    input clk,
    input nRST,
    input requireAC, // whether the ALU is available and ins can be issued，来自memory的avaible信号
    //表示当前memory能不能使用，由于memory读写需要延时，所以要等延时结束了才能用
    input WEN, // Write ENable，来自CU的ResStationEN，三个Queue都接入到该信号的第3个
    output isFull, // whether the buffer is full，只有RT队列该信号接入到CU的isFull的2号下标，其它俩队列都没接
    output require, // whether output is valid，三个队列组成的2:0信号经过一个与门输入到memory的WEN里
    //表示是否存在数据需要issue，也就是只有当三个队列都有数据需要issue的时候memory才可以开始工作

    input [31:0] dataIn,//三个队列的dataIn接入的地方各不相同
    input [3:0] labelIn,//三个队列的该信号接入的地方也不一样，Immd直接接地了
    input opIN,//三个队列的该信号都接入到了CU的QueueOp上，之后这个信号会送给opOut，
    //所以CU的QueueOp应该是读写控制信号

    input BCEN, // BroadCast ENable，接到CDB的EN上
    input [3:0] BClabel, // BoradCast label，接到CDB的labelOut上
    input [31:0] BCdata, //BroadCast value，接到CDB的dataOut上

    output opOut,//只有RT队列的该信号接入到了memory的op上，控制读写，高电平读，低电平写
    output [31:0] dataOut,//三个队列的该输出分别接入到memory的dataIn1和dataIn2和writeData上
    //dataIn1和dataIn2之和控制读写的地址
    output [3:0] labelOut,//只有RT队列的labelOut接到了memory的labelIn上，
    //memory直接把label输出到CDB，应该是1100部分的保留站编号
    input isLastState,//来自memory的isLastState，在读取或写入延时的最后一个周期其为1
    output [3:0] queue_writeable_label//只有RT队列的该信号接入到了四选一的一个输出上，
    //该信号和保留站的writeable_labelOut是同义的应该，内容是1100部分的保留站编号
    );
    //三个项中可用的那一个
    reg [3:0]availableIdLabel;
    assign queue_writeable_label = availableIdLabel;
    //各个项是否可用
    reg [3:0]Busy;
    //label是产生指令中RS操作数的label
    reg [3:0]Label[3:0];
    //data是RS操作数
    reg [31:0]Data[3:0];
    //idlabel是当前数据存在存储保留站的哪个label上
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

    //表示是否可以输出，当需要进行输出且memory可用的时候才可以输出
    wire issuable = require && requireAC;
    //表示是否三个项全满了
    wire wbusy = Busy[0] && Busy[1] && Busy[2]; //三位二进制相与
    //当三个项全满了并且不能流出的时候是full状态
    assign isFull = !issuable && wbusy;
    //require表示是否存在数据需要issue，0号项busy且数据已经准备好的话就可以输出了
    assign require = Busy[0] && Label[0] == 0;
    wire poppable;
    //当memory的延时进入只剩下一个clk就可以完成的时候，队列可以pop
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

    //寻找可用的那一项
    always@(*) begin
        if (wbusy) 
        //三个都忙的时候没有项可以使用
            availableIdLabel = 4'bx; // if busy, it is don't-care signal
        else if (IdLabel[0] != `QUE0 && IdLabel[1] != `QUE0 && IdLabel[2] != `QUE0)
        //如果不满足if(wbusy)条件，则必然至少有一个项不是busy的，由于busy的更新和idLabel是同步的，
        //所以必然三个项号里有一个项号是可以使用的，所以此时availableIdLabel必然可以得到可以使用的项号
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
                //目前只有一条指令WEN等于1，所以先不管这里了
                //没看懂
                    if (!poppable) begin
                        //对于RS队列：把源操作数读入到空闲的项，并对busy的项更新
                        if (!wbusy && i == first_empty) begin //Wen && !issuable && !busy
                            // input data to the first empty position
                            Busy[i] <= 1;
                            //对于RS队列，如果CDB的数据是指令里的源操作数，那空项的数据为该源操作数，
                            //否则为寄存器里读到的源操作数
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
                //对于WEN为0的指令，如果可以pop的话，除了最后一项以外其它项前移一位，最后一项清零
                    if (poppable) begin
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
                    //不能pop的时候更新所有项
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