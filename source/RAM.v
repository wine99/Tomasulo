`timescale 1ns / 1ps
// 信任提供地址和数据的模块，在内存未完成操作的时�?�，addr和data不改�?
module RAM(
    input clk,
    input [31:0] address,
    input [31:0] writeData, // [31:24], [23:16], [15:8], [7:0]
    input nRD, // �?0，正常读；为1,输出高组�?
    input nWR, // �?0，写；为1，无操作
    output reg [31:0] Dataout,
    output reg readStatus, // 如果输出有效则为1
    //readStatus��writeStatus�ֱ��ʾ��ȡ��д������Ƿ�ɹ�
    output reg writeStatus,
    output isLastState
    );
    //RAM��һ���洢����ģ������ʵ�Ĵ洢��ʵ���˶�ȡ�Ͷ�������ʱ
    //R��W�ֱ���ƶ�ȡ��д�룬����Ҫ���ж�ȡ��ʱ��R���0�ӵ�1��֮��ÿ��clk
    //�½��ض���һ����ֱ��RΪ10��ʱ��Ž��ж�ȡ����������ģ���˶�ȡ����ʱ
    //����Ҫд���ʱ��W���0�ӵ�1��WΪ1��ʱ��������д�룬���Ǳ�־д��
    //�ɹ��ı�־����ʧ�ܣ��������޸ģ�֮��ÿ��CLK�½���W��һ
    //��W�ӵ�10��ʱ�򣬰�д��ɹ���־�ĳ�1����ʾд��ɹ�������ģ����д����ʱ
    integer R,W;
    assign isLastState = R == 9 || W == 9; //TODO
    initial begin
      R = 0;
      W = 0;
      readStatus = 0;
      writeStatus = 0;
    end
    reg [7:0] ram [0:60]; //存储�?
    // 设置状�?�变�?
    always@( negedge clk) begin
        if (R == 0) begin
            if (nRD == 0) begin
                R <= 1;
            end
            else begin // nRD == 1
                R <= 0;
            end
        end
        else if (R == 10) begin
            R <= 0;            
        end
        else begin
            R <= R+1;
        end

        if (W == 0) begin
            if (nWR == 0) begin
                W <= 1;
            end
            else begin // nWR == 1
                W <= 0;
            end
        end
        else if (W == 10) begin
            W <= 0;            
        end
        else begin
            W <= W+1;
        end
    end
    always@(*) begin
        // if (readStatus == 1) begin
        if (R == 10) begin
            Dataout[7:0] = ram[address + 3]; 
            Dataout[15:8] = ram[address + 2];
            Dataout[23:16] = ram[address + 1];
            Dataout[31:24] = ram[address ];
            readStatus = 1;
        end
        else begin
            readStatus = 0;
        end
        if( W == 1 ) begin
            ram[address] = writeData[31:24];
            ram[address+1] = writeData[23:16];
            ram[address+2] = writeData[15:8];
            ram[address+3] = writeData[7:0];
        end
        if (W == 10) begin
            writeStatus = 1;
        end
        else begin
            writeStatus = 0;
        end
    end
endmodule