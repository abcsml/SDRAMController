# SDRAM Controller

# 串口收发模块

## 串口接收模块
![](https://svg.wavedrom.com/github/abcsml/SDRAMController/master/doc/wave/uart_rx_wave.json)

| 信号        | 方向     | 描述                                                         |
| ----------- | -------- | ------------------------------------------------------------ |
| rx          | input    | 串口输入信号，为高表示空闲，拉低表示准备发送数据，之后发8个字节数据（低位优先），发完后保持高电平 |
| rx1,rx2,rx3 | internal | 跨时钟域处理，对rx进行打两拍处理，rx3为rx_flag使用           |
| rx_flag     | internal | 为高表示串口处于接收状态，下降沿到来时拉高                             |
| baud_cnt    | internal | 波特率计数器，设fpga时钟频率为f Hz，则串口发送1bit数据周期数为(1/b)*f。（当f为50M时，波特率b为9600时，周期数约为5208） |
| bit_flag    | internal | 为高表示串口数据有效，取中间值增加稳定性，（5208/2 = 2604）  |
| bit_cnt     | internal | 在一次接收中，已经接收到的bit数，自增条件为bit_flag为高（数值0-8） |
| rx_data     | output   | 输出串口数据，串转并                                         |
| po_flag     | output   | 为高表示传输完毕                                             |


## 串口发送模块
![](https://svg.wavedrom.com/github/abcsml/SDRAMController/master/doc/wave/uart_tx_wave.json)

| 信号        | 方向     | 描述                                                         |
| ----------- | -------- | ------------------------------------------------------------ |
| tx_trig     | input    | 为高表示tx_data数据有效                                      |
| tx_data     | input    | 串口要发送的数据                                             |
| tx_data_reg | internal | 缓存tx_data数据的寄存器                                      |
| tx_flag     | internal | 为高表示串口处于发送状态                                     |
| baud_cnt    | internal | 波特率计数器，和接收模块相同                                 |
| bit_flag    | internal | 检测串口数据信号（波特率计满产生）                           |
| bit_cnt     | internal | 在一次发送中，已经发送的bit数，自增条件为bit_flag为高（数值0-8） |
| tx          | output   | 串口数据发送端，当tx_flag拉高且bit_cnt==0时作为起始位，低电平有效之后发送8bit数据 |

# SDRAM

SDRAM引脚

| 引脚       | 名称         | 描述                         |
| ---------- | ------------ | ---------------------------- |
| Clk        | Clock        | 时钟，所有信号依赖时钟上升沿 |
| CKE        | Clock Enable | 内部时钟使能信号             |
| CS         | Chip Select  | 片选信号，拉低有效           |
| BA0 BA1    | Bank Address | Bank地址                     |
| A0-A11     | Address      | 地址线，可以是行，也可以是列      |
| RAS CAS WE |              | 用来发命令                   |
| UDQM LDQM  | Data IO Mask | 数据掩码                     |
| DQ0-DQ15   | Data IO      | 双向数据线                 |

SDRAM模式寄存器

| BA1 | BA0 | A11 | A10 | A9      | A8  | A7  | A6-A4       | A3  | A2-A0        |
| --- | --- | --- | --- | ------- | --- | --- | ----------- | --- | ------------ |
| 0   | 0   | 0   | 0   | OP Code | 0   | 0   | CAS Latency | BT  | Burst Length | 

## SDRAM初始化

初始化过程
![](img/Pasted%20image%2020230201110408.png)

命令
| Cmd   | CS  | RAS | CAS | WE  |
| --------- | --- | --- | --- | --- |
| Precharge | 0   | 0   | 1   | 0   |
| A-Refresh | 0   | 0   | 0   | 1   |
| NOP       | 0   | 1   | 1   | 1   |
| Mode-Set  | 0   | 0   | 0   | 0   |
| Active    | 0   | 0   | 1   | 1   |
| Write     | 0   | 1   | 0   | 0   |
| Read      | 0   | 1   | 0   | 1   |

时间间隔
tRP: 20ns  1clk
tRC: 63ns  4clks

地址（配置模式寄存器）
addr:  12'b0000_0011_0010

![](https://svg.wavedrom.com/github/abcsml/SDRAMController/master/doc/wave/sdram_init_wave.json)

| 信号          | 方向     | 描述                                                                                                   |
| ------------- | -------- | ------------------------------------------------------------------------------------------------------ |
| cnt_200us     | internal | 200us计时器（假设1clk为20ns，200us为10000clks）                                                                        |
| flag_200us    | internal | 为高表示200us已过                                                                                      |
| cnt_cmd       | internal | 时钟计数器，200us后为0时，发送Precharge命令，为1时发送AUTO Refresh，5发送AUTO Refresh，9加载模式寄存器 |
| cmd_reg       | output   | 输出当前指令                                                                                        |
| sdram_addr    | output   | 输出当前地址                                                                                             |
| flag_init_end | output   | 初始化结束标志信号                                                                                                       |

## SDRAM仲裁

SDRAM仲裁状态机
![](img/shot2023-02-05%20105002.png)

## SDRAM刷新

![](https://svg.wavedrom.com/github/abcsml/SDRAMController/master/doc/wave/sdram_aref_wave.json)

| 信号          | 方向     | 描述                                                                     |
| ------------- | -------- | ------------------------------------------------------------------------ |
| flag_aref_ask | output   | 请求刷新信号，aref_cnt计数满后拉高                                       |
| aref_en       | input    | 允许刷新信号，刷新结束后应立刻拉低                                    |
| aref_cnt      | internal | 计时器，每周期自加1，加满后表示需要刷新，en高时置零（4096refreshs/64ms） |
| cmd_cnt       | internal | 周期计数器，en高时自加，低时归零，最高为10                               |
| sdram_cmd     | output   | 根据cmd_cnt输出指令，和init过程一样                                            |
| sdram_addr    | output   | 恒为12'b0100_0000_0000                                                   |
| flag_aref_end | output   | 表示此次刷新结束，当cmd_cnt为10时拉高 |


## SDRAM 写

![](https://svg.wavedrom.com/github/abcsml/SDRAMController/master/doc/wave/sdram_write_wave1.json)

| 信号        | 方向     | 描述                                                                                                                      |
| ----------- | -------- | ------------------------------------------------------------------------------------------------------------------------- |
| wr_trig     | input    | 表示有数据来了，准备写入SDRAM                                                                                             |
| flag_wring  | internal | 表示有正在处理的写任务，遇见wr_trig拉高，最后一个burst信号发出后拉低                                                              |
| flag_wr_ask | output   | 写请求，有写任务时拉高，仲裁允许后(wr_en为高)拉低，和S_ASK状态同步                                                        |
| wr_en       | input    | 写使能，由仲裁器发出，表示允许写模块运作，当有更高优先级任务时(如AREF)会拉低，此时应该等待当前burst完成后，立刻退出WR状态 |
| state       | internal | 状态机，5种状态，S_ACT，S_PRE固定两个周期<br>1、IDLE遇到trig变为ASK<br>2、ASK遇到使能信号变为ACT<br>3、ACT遇到act_end变为WR<br>4、WR遇到wr_end变为PRE<br>5、PRE根据三种不同情况分别跳转到ACT，ASK，IDLE，可以根据en和flag_wring信号判断 |
| s_act_end   | internal | S_ACT状态结束信号                                                                                                             |
| s_pre_end   | internal | S_PRE状态结束信号                                                                                                             |
| s_wr_end    | internal | S_WR状态结束信号(换行，en拉低，wring拉低)                                                                          |
| s_wr_row    | internal | 拉高表明该写下一行                 |
| flag_wr_end | output   | 拉高表示交出主动权(中途刷新退出，或写任务结束)                      |

![](https://svg.wavedrom.com/github/abcsml/SDRAMController/master/doc/wave/sdram_write_wave2.json)

| 信号               | 方向     | 描述                                                          |
| ------------------ | -------- | ------------------------------------------------------------- |
| burst_cnt[1:0]     | internal | 4次burst，记录当前为第几次                            |
| sdram_cmd[3:0]     | output   | 写模块输出命令                                                |
| sdram_addr[11:0]   | output   | 输出地址，行：0-11，列：0-8|
| sdram_bank[1:0]    | output   | 当前恒为0  |
| sdram_data[15:0]   | output   | 由wr_data给出   |
| rem_burst_len[7:0] | internal | 剩余burst次数(WR状态，burst_cnt为0时自减)                     |

其他信号

| 信号          | 方向     | 描述                                                  |
| ------------- | -------- | ----------------------------------------------------- |
| wr_data[15:0] | input    | 当前要写入SDRAM的数据，配合wr_data_en使用             |
| wr_data_en    | output   | 表示当前data正在被写入，提醒在下个周期更换wr_data数据 |
| wr_addr[20:0] | input    | 起始的写位置，必须按4字节对齐                         |
| wr_len[7:0]   | input    | 此次写入SDRAM数据burst次数                            |
| row_addr[11:0]| internal | 行地址                                                |
| col_addr[8:0] | internal | 列地址                                                |


**读模块逻辑相同，不再写文档**

只是换个名字，加一个计数器（burst_cnt_t）用来计算2个周期延迟


## 命令解析模块

![](https://svg.wavedrom.com/github/abcsml/SDRAMController/master/doc/wave/cmd_decode_wave.json)

| 信号        | 方向     | 描述                                                    |
| ----------- | -------- | ------------------------------------------------------- |
| uart_flag   | input    | 表示收到数据(po_flag，为高时数据有效)                   |
| uart_data   | input    | 串口接收到的数据，h55表示写，后面跟4个写数据；haa表示读 |
| rec_num     | internal | 写数据计数                                              |
| cmd_reg     | internal | 0:空闲，1:处于写状态，2:处于读状态                      |
| wr_trig     | output   | 写触发                                                  |
| rd_trig     | output   | 读触发                                                  |
| wfifo_wr_en | output   | 写fifo使能                                              |
