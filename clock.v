`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/10/06 22:00:36
// Design Name: 
// Module Name: clock
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

/*构造一个 24 小时制的数字钟。要求能显示时、分、秒（用数码管加 LED 来完成）。
1.能利用板上的微动开关作时钟的调整。 2.用板上的 LED 的闪烁作整点报时。 
实验扩展要求
1.增加 12/24 小时显示切换模式。 2.加入闹铃功能。 3.增加清零功能。
*/


module clock(            //主模块
    input rst,
    input [4:0]button,//5个微动开关  
    input clk,//时钟
    output [7:0]led_bits,//数码管的使能端
    output [6:0]sm_a_to_g,//数码管sm
    output [6:0]h_a_to_g,//数码管h
    output [7:0]led//LED整点报时done
    );
    reg [35:0]clk_cnt;//计数器    
    reg [7:0] second,minute,hour;//time
    reg set_mode;//调时模式
    reg shift_mode;
    reg alarm_mode;
    
    wire [31:0]my_div;//秒
    wire [4:0]r_button;//去抖后的开关
    wire clr=r_button[0];//清零done放到计时模块了
    wire alarm=r_button[1];//闹铃
    wire shift=r_button[2];//12/24小时切换done数码管模块
    wire set=r_button[3];//进入调时模式done计时模块
    wire set_time=r_button[4];//调时：秒 分 时
    reg flag_set,mode;
    reg [2:0]set_count;
    //清零以及模式设置
    always@(posedge clk or negedge rst)
    begin
        if(!rst)
        begin
            second=0;minute=0;hour=0;set_mode=0;shift_mode=0;alarm_mode=0;flag_set=0;set_count=0;mode=0;
        end
        else
        begin
            mode=set_mode|shift_mode|alarm_mode;
            if(alarm)alarm_mode=1;
            if(shift)shift_mode=1;
            if(set)set_mode=1;else if(!flag_set)set_mode=0;

        end
    end

Elimination_Buffeting myEB(
.button(button),
.clk(clk),
.r_button(r_button)
);//按键去抖
numerical_code_tube myNumerical_Code_Tube(//数码管显示模块
.hour(hour),//记录时间，高位记录十位，低位记录个位
.minute(minute),
.second(second),
.clk1(clk_cnt[15:13]),//时钟clk_cnt[15:13]
.shift_mode(shift_mode),
.sm_a_to_g(sm_a_to_g),
.h_a_to_g(h_a_to_g), 
.nct_led_bits(led_pins)
);
//分频模块
Time_Frequency my_Time_Frequency(
.clk(clk),
.key(clr),
.rst(rst),//按下按键数据清零
.second_fq(my_div),//在一秒内从0变化到N-1
.clk_cnt(clk_cnt)
);
caculate caculate_time(//计算时间
.s_div(my_div),//秒
.clk(clk),
.clr(clr),
.set_mode(set_mode),
.key_time(set_time),
.rst(rst),
.set_count(set_count),//?
.second(second),
.minute(minute),
.hour(hour)
);
chime(//报时模块
.second(second),
.minute(minute),
.hour(hour),
.clk_cnt(clk_cnt),
.mode(mode),
.rst(rst),
.led(led)
);
//调时模块
AdjustTime adjust_my_time(
.rst(rst),
.set(set),
.set_mode(set_mode),
.flag_set(flag_set),
.set_count(set_count)
);

endmodule



//按键消抖
module Elimination_Buffeting(
    input[4:0] button,
    input clk,
    output[4:0] r_button
    );
    reg [4:0] button_dly;
    always@(posedge clk)
    begin
        button_dly<=button;
    end
    assign r_button=button&button_dly;
endmodule

//数码管显示模块
module numerical_code_tube(
input[7:0] hour,//记录时间，高位记录十位，低位记录个位
input[7:0] minute,
input[7:0] second,
input [2:0]clk1,//时钟clk_cnt[15:13]
input shift_mode,
output reg [6:0] sm_a_to_g,
output reg [6:0] h_a_to_g, 
output[7:0] nct_led_bits
);
reg[7:0]h,m,s;
reg[3:0] num;
reg[7:0]led_bits;
assign nct_led_bits=led_bits;

always@(*)//12/24切换
begin
    m=minute;
    s=second;
    if(shift_mode&&(hour[7:4]==2||hour[7:4]==1&&hour[3:0]>=2))//12小时模式且hour大于等于12
        h={hour[7:4]-1,hour[3:0]-2};
    else h=hour;//12小时模式且hour小于12   
end

always@(*)
begin
case(num)
    1:begin sm_a_to_g=7'b0110000;h_a_to_g=7'b0110000;end
    2:begin sm_a_to_g=7'b1101101;h_a_to_g=7'b1101101;end
    3:begin sm_a_to_g=7'b1111001;h_a_to_g=7'b1111001;end
    4:begin sm_a_to_g=7'b0110011;h_a_to_g=7'b0110011;end
    5:begin sm_a_to_g=7'b1011011;h_a_to_g=7'b1011011;end
    6:begin sm_a_to_g=7'b1011111;h_a_to_g=7'b1011111;end
    7:begin sm_a_to_g=7'b1110000;h_a_to_g=7'b1110000;end
    8:begin sm_a_to_g=7'b1111111;h_a_to_g=7'b1111111;end
    9:begin sm_a_to_g=7'b1111011;h_a_to_g=7'b1111011;end
    default:begin sm_a_to_g=7'b1111110;h_a_to_g=7'b1111110;end
endcase
end
always@(*)
begin
case(clk1)
    0:begin num=s[3:0];led_bits=8'b00000001;end
    1:begin num=s[7:4];led_bits=8'b00000010;end
    2:begin num=m[3:0];led_bits=8'b00000100;end
    3:begin num=m[7:4];led_bits=8'b00001000;end
    4:begin num=h[3:0];led_bits=8'b00010000;end
    5:begin num=h[7:4];led_bits=8'b00100000;end
    default:led_bits=0;
    endcase
end
endmodule

//分频模块
module Time_Frequency(
input clk,
input key,
input rst,//按下按键数据清零
output [31:0] second_fq,//在一秒内从0变化到N-1
output [35:0]clk_cnt
);
parameter N=100000000;//N*100MHz=1s
reg [31:0]second_count;
reg [35:0]clk_count;

assign second_fq=second_count;
assign clk_cnt=clk_count;

always@(posedge clk)
begin
    if(second_count<N)
    second_count<=second_count+1;
    else
    second_count<=0;
end
always@(posedge key or negedge rst)
begin
    second_count<=0;
end
always@(posedge clk)
begin
    clk_count=clk_count+1;
end

endmodule

module caculate(//计算时间
input [31:0]s_div,//秒
input clk,
input clr,
input set_mode,
input key_time,
input rst,
input [2:0]set_count,
output [7:0]second,
output [7:0]minute,
output [7:0]hour
);
reg [7:0]s,m,h;
assign second=s;
assign minute=m;
assign hour=h;
always@(posedge clk)
begin
    if(clr)
    begin
        s=0;m=0;h=0;
    end
    else
    if(s_div[31:0]==0&&!set_mode)begin//在没有进入模式条件下，每过一秒进行下列操作
        begin if(s[3:0]<9)//++s
        s[3:0]=s[3:0]+1;
        else begin s[7:4]=s[7:4]+1;s[3:0]=0;end
        end
        if(s[7:4]>=6)begin
            s[7:0]=0;
            begin if(m[3:0]<9)//++m
                m[3:0]=m[3:0]+1;
                else begin m[7:4]=m[7:4]+1;m[3:0]=0;end
                end
            if(m[7:4]>=6)begin
                m[7:0]=0;
                begin if(h[3:0]!=2|h[7:4]!=4)//++h
                    if(h[3:0]<9)
                        h[3:0]=h[3:0]+1;
                    else begin h[3:0]=0;h[7:4]=h[7:4]+1;end
                end
                if(h[3:0]==4&h[7:4]==2)
                    h[7:0]=0;                 
             end   
        end
    end
end
always@(posedge key_time or negedge rst)//在不同模式下，每按一下键，时间就加一
    if(rst)
    begin
        if(set_count==1)//++second
        begin
            if(s[3:0]<9)   
                s[3:0]=s[3:0]+1;
            else begin
                s[3:0]=0;
                if(s[7:4]<6)
                    s[7:4]=s[7:4]+1;
                else s[7:4]=0;
            end
        end
        else if(set_count==2)//++minute
            begin
                if(m[3:0]<9)   
                    m[3:0]=m[3:0]+1;
                else begin
                    m[3:0]=0;
                    if(m[7:4]<6)
                        m[7:4]=m[7:4]+1;
                    else m[7:4]=0;
                end                    
            end
            else if(set_count==3)//++hour
                begin
                    if(h[7:4]==2&&h[3:0]==3)
                        h=0;
                    else begin
                        if(h[3:0]==9)
                        begin
                            h[3:0]=0;h[7:4]=h[7:4]+1;
                        end
                        else begin
                            h[3:0]=h[3:0]+1;
                        end
                    end    
                end
    end

endmodule

//报时模块,模式中不触发
module chime(
input [7:0]second,
input [7:0]minute,
input [7:0]hour,
input [35:0]clk_cnt,
input mode,
input rst,
output [7:0]led
);

reg [7:0]c_led;
reg [4:0]h;//记录整点时间
reg [5:0]H;
reg[4:0]T;//BCD转Binary的中间变量
reg freq;

assign led=c_led;

always@(*)begin
freq=clk_cnt[25];
end

always@(*)//获得整点时间
begin
    if(!rst)
        begin H=0;c_led=0;end
    else if(second==0&&minute==0&&mode==0)
        begin
            T[4]=hour[5];T[3]=hour[4];T[2]=hour[5];T[1]=hour[4];T[0]=0;
            h=T+{1'b0,hour[3:0]};
            H=h+h;
        end
end

always@(posedge freq)//LED灯以二进制的方式用频率freq闪烁h次//LED貌似只需要5个
begin
    if(H>0&&mode==0)
    begin
        if(H[0]==0)
        begin
            c_led=h;
            H=H-1;
        end
        else
        begin
            c_led=0;
            H=H-1;
        end
        
    end
    else 
    begin
        H=0;
        c_led=0;
    end
end
endmodule

//调时模块
module AdjustTime(rst,set,set_mode,flag_set,set_count);
input rst;
input set;
input set_mode;//模式1：调秒 模式2：调分 模式3：调时 模式0：退出
output reg flag_set;//用于改变输入set_mode的值
output reg [2:0]set_count;

always@(posedge set or negedge rst)//
begin
    if(!rst)
        set_count=0;
    else
    begin
        if(set_mode)
            set_count=set_count+1;//用于模式切换
        if(!set_count||!set_mode)//结束模式
            flag_set=0;
        else flag_set=1;
    end
end
endmodule

//闹铃模块
//达到设定时间自动闪灯

