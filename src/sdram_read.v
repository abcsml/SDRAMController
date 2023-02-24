module sdram_read(
    input                   sclk,
    input                   srst_n,
    // Control
    input                   rd_en,
    output                  flag_rd_ask,
    output                  flag_rd_end,
    // Other
    input                   rd_trig,
    input       [ 7:0]      rd_len,
    input       [20:0]      rd_addr,
    output  reg [15:0]      rd_data,
    output                  rd_data_en,
    output  reg [ 3:0]      sdram_cmd,
    output      [11:0]      sdram_addr,
    output  reg [ 1:0]      sdram_bank,
    input       [15:0]      sdram_data
);

parameter       CASL    =   3'b011;   

localparam      CMD_NOP =   4'b0111;
localparam      CMD_ACT =   4'b0011;
localparam      CMD_RD  =   4'b0101;
localparam      CMD_PRE =   4'b0010;

localparam      S_IDLE  =   5'b00001;
localparam      S_ASK   =   5'b00010;
localparam      S_ACT   =   5'b00100;
localparam      S_RD    =   5'b01000;
localparam      S_PRE   =   5'b10000;

reg                     flag_rding;
reg                     s_act_end;
reg                     s_pre_end;
reg                     s_rd_end;

reg [ 4:0]              state;
reg                     s_rd_row;
reg [ 1:0]              burst_cnt;
reg [ 2:0]              burst_cnt_t;
reg [ 7:0]              rem_burst_len;

reg [11:0]              row_addr;
reg [ 8:0]              col_addr;

// State
always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        state   <=  S_IDLE;
    else case (state)
        S_IDLE: state   <=  rd_trig ? S_ASK : S_IDLE;
        S_ASK:  state   <=  rd_en ? S_ACT : S_ASK;
        S_ACT:  state   <=  s_act_end ? S_RD : S_ACT;
        S_RD:   state   <=  s_rd_end ? S_PRE : S_RD;
        S_PRE:  begin
            if (s_pre_end && !flag_rding)
                state   <=  S_IDLE;
            else if (s_pre_end && rd_en)
                state   <=  S_ACT;
            else if (s_pre_end && !rd_en)
                state   <=  S_ASK;
        end
        default:    state   <=  state;
    endcase
end

// Internal flag
always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        flag_rding  <=  1'b0;
    else if (rd_trig)
        flag_rding  <=  1'b1;
    else if (rem_burst_len == 'd0)
        flag_rding  <=  1'b0;
end

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        s_act_end   <=  1'b0;
    else if (state == S_ACT && s_act_end == 1'b0)
        s_act_end   <=  1'b1;
    else
        s_act_end   <=  1'b0;
end

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        s_pre_end   <=  1'b0;
    else if (state == S_PRE && s_pre_end == 1'b0)
        s_pre_end   <=  1'b1;
    else
        s_pre_end   <=  1'b0;
end

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        s_rd_end    <=  1'b0;
    else if (state == S_RD && burst_cnt == 'd3 &&
        (s_rd_row == 'b1 || rd_en == 'b0 || flag_rding == 'b0))
        s_rd_end    <=  1'b1;
    else
        s_rd_end    <=  1'b0;
end

// Control
assign  flag_rd_ask =   state == S_ASK;
assign  flag_rd_end =   (!flag_rding & s_pre_end) | (!rd_en & s_pre_end);

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        s_rd_row  <=  1'b0;
    else if (rd_trig)
        s_rd_row  <=  1'b0;
    else if (state != S_RD)
        s_rd_row  <=  1'b0;
end

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        burst_cnt   <=  'b0;
    else if (state  ==  S_RD)
        burst_cnt   <=  burst_cnt + 1'b1;
    else
        burst_cnt   <=  'b0;
end

always @(posedge sclk) begin
    if (!srst_n)
        burst_cnt_t <=  'd0;
    else if (burst_cnt == CASL)
        burst_cnt_t <=  'd4;
    else if (burst_cnt_t != 'd0)
        burst_cnt_t <=  burst_cnt_t - 'd1;
end

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        rem_burst_len   <=  'b0;
    else if (rd_trig)
        rem_burst_len   <=  rd_len;
    else if (state == S_RD && burst_cnt == 'b0)
        rem_burst_len   <=  rem_burst_len - 1'b1;
end

// Other
assign  sdram_addr  =   (state == S_PRE) ? 12'b0100_0000_0000 :
                        (state == S_ACT) ? row_addr : col_addr;
assign  rd_data_en  =   burst_cnt_t != 'd0;
// assign  rd_data     =   sdram_data;

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        rd_data <= 'd0;
    else
        rd_data <= sdram_data;
end


always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        sdram_cmd   <=  CMD_NOP;
    else if (state == S_ACT && !s_act_end)
        sdram_cmd   <=  CMD_ACT;
    else if (state == S_RD && burst_cnt == 'd0 && !s_rd_end)
        sdram_cmd   <=  CMD_RD;
    else if (state == S_PRE && !s_pre_end)
        sdram_cmd   <=  CMD_PRE;
    else
        sdram_cmd   <=  CMD_NOP;
end

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        sdram_bank  <=  'b0;
end

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        row_addr    <=  'b0;
    else if (rd_trig)
        row_addr    <=  rd_addr[20:9];
    else if (s_rd_row && s_rd_end)
        row_addr    <=  row_addr + 1'b1;
end

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        col_addr    <=  'b0;
    else if (rd_trig)
        col_addr    <=  rd_addr[8:0];
    else if (state == S_RD && burst_cnt == 'd1)
        {s_rd_row, col_addr}    <=  {1'b0, col_addr} + 'd4;
end

endmodule //sdram_read
