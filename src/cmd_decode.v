module cmd_decode (
    input                   sclk,
    input                   srst_n,

    input                   uart_flag,
    input       [ 7:0]      uart_data,
    output                  wr_trig,
    output                  rd_trig,
    output                  wfifo_wr_en
);

localparam  CMD_WRITE   =   8'h55;
localparam  CMD_READ    =   8'haa;

localparam  S_NOP       =   0;
localparam  S_WRITE     =   1;
localparam  S_READ      =   2;

reg [ 1:0]              rec_num;
reg [ 1:0]              cmd_reg;


always @(posedge sclk or negedge srst_n) begin
    if(!srst_n)
        rec_num <= 0;
    else if (cmd_reg == S_WRITE && uart_flag)
        rec_num <= rec_num + 'd1;
    else if (cmd_reg != S_WRITE)
        rec_num <= 'd0;
end

always @(posedge sclk or negedge srst_n) begin
    if(!srst_n)
        cmd_reg <= S_NOP;
    else if (cmd_reg == S_NOP && uart_flag && uart_data == CMD_WRITE)
        cmd_reg <= S_WRITE;
    else if (cmd_reg == S_NOP && uart_flag && uart_data == CMD_READ)
        cmd_reg <= S_NOP;
    else if (cmd_reg == S_WRITE && uart_flag && rec_num == 'd3)
        cmd_reg <= S_NOP;
    else if (cmd_reg == S_READ && uart_flag)
        cmd_reg <= S_NOP;
end

assign  wr_trig     =   uart_flag && rec_num == 'd3;
assign  rd_trig     =   uart_flag && cmd_reg == S_NOP && uart_data == CMD_READ;
assign  wfifo_wr_en =   uart_flag && cmd_reg == S_WRITE;

endmodule //cmd_decode
