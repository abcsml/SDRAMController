# SDRAM Controller

## 串口收发模块

### 串口接收模块
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


### 串口发送模块
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
