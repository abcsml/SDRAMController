module sdram_write(
    input                   sclk,
    input                   srst_n,
    // Control
    input                   wr_en,
    output                  flag_wr_ask,
    output                  flag_wr_end,
    // Other
    input                   wr_trig,
    input       [ 7:0]      wr_len,
    input       [15:0]      wr_data,
    input       [20:0]      wr_addr,        // 必须对齐
    output                  wr_data_en,
    output  reg [ 3:0]      sdram_cmd,
    output      [11:0]      sdram_addr,
    output  reg [ 1:0]      sdram_bank,
    output      [15:0]      sdram_data
);

localparam      CMD_NOP =   4'b0111;
localparam      CMD_ACT =   4'b0011;
localparam      CMD_WR  =   4'b0100;
localparam      CMD_PRE =   4'b0010;

localparam      S_IDLE  =   5'b00001;
localparam      S_ASK   =   5'b00010;
localparam      S_ACT   =   5'b00100;
localparam      S_WR    =   5'b01000;
localparam      S_PRE   =   5'b10000;

reg                     flag_wring;
reg                     s_act_end;
reg                     s_pre_end;
reg                     s_wr_end;

reg [ 4:0]              state;
reg                     s_wr_row;
reg [ 1:0]              burst_cnt;
reg [ 1:0]              burst_cnt_t;
reg [ 7:0]              rem_burst_len;

reg [11:0]              row_addr;
reg [ 8:0]              col_addr;

// State
always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        state   <=  S_IDLE;
    else case (state)
        S_IDLE: state   <=  wr_trig ? S_ASK : S_IDLE;
        S_ASK:  state   <=  wr_en ? S_ACT : S_ASK;
        S_ACT:  state   <=  s_act_end ? S_WR : S_ACT;
        S_WR:   state   <=  s_wr_end ? S_PRE : S_WR;
        S_PRE:  begin
            if (s_pre_end && !flag_wring)
                state   <=  S_IDLE;
            else if (s_pre_end && wr_en)
                state   <=  S_ACT;
            else if (s_pre_end && !wr_en)
                state   <=  S_ASK;
        end
        default:    state   <=  state;
    endcase
end

// Internal flag
always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        flag_wring  <=  1'b0;
    else if (wr_trig)
        flag_wring  <=  1'b1;
    else if (rem_burst_len == 'd0)
        flag_wring  <=  1'b0;
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
        s_wr_end    <=  1'b0;
    else if (state == S_WR && burst_cnt == 'd3 &&
        (s_wr_row == 'b1 || wr_en == 'b0 || flag_wring == 'b0))
        s_wr_end    <=  1'b1;
    else
        s_wr_end    <=  1'b0;
end

// Control
assign  flag_wr_ask =   state == S_ASK;
assign  flag_wr_end =   (!flag_wring & s_pre_end) | (!wr_en & s_pre_end);

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        s_wr_row  <=  1'b0;
    else if (wr_trig)
        s_wr_row  <=  1'b0;
    else if (state != S_WR)
        s_wr_row  <=  1'b0;
end

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        burst_cnt   <=  'b0;
    else if (state  ==  S_WR)
        burst_cnt   <=  burst_cnt + 1'b1;
    else
        burst_cnt   <=  'b0;
end

always @(posedge sclk) begin
    burst_cnt_t     <=  burst_cnt;
end

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        rem_burst_len   <=  'b0;
    else if (wr_trig)
        rem_burst_len   <=  wr_len;
    else if (state == S_WR && burst_cnt == 'b0)
        rem_burst_len   <=  rem_burst_len - 1'b1;
end

// Other
assign  wr_data_en  =   (state == S_WR) && (burst_cnt == 'b0);
assign  sdram_addr  =   (state == S_PRE) ? 12'b0100_0000_0000 :
                        (state == S_ACT) ? row_addr : col_addr;
assign  sdram_data  =   wr_data;

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        sdram_cmd   <=  CMD_NOP;
    else if (state == S_ACT && !s_act_end)
        sdram_cmd   <=  CMD_ACT;
    else if (state == S_WR && burst_cnt == 'd0 && !s_wr_end)
        sdram_cmd   <=  CMD_WR;
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
    else if (wr_trig)
        row_addr    <=  wr_addr[20:9];
    else if (s_wr_row && s_wr_end)
        row_addr    <=  row_addr + 1'b1;
end

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        col_addr    <=  'b0;
    else if (wr_trig)
        col_addr    <=  wr_addr[8:0];
    else if (state == S_WR && burst_cnt_t == 'd0 && burst_cnt == 'd1)
        {s_wr_row, col_addr}    <=  {1'b0, col_addr} + 'd4;
end

endmodule //sdram_write
