`define SIM

module uart_tx(
	input				clk,
	input				rstn,
	input				tx_trig,
	input	[7:0]		tx_data,
	output	reg			tx,
	output	reg			tx_busy
);

localparam	FPGA_FREQ	=	50_000_000;
localparam	BAUD_RATE	=	9600;
localparam	BIT_END		=	9;

`ifndef SIM
localparam	BAUD_END	=	(1/BAUD_RATE)*FPGA_FREQ;
`else
localparam	BAUD_END	=	56;
`endif

localparam	BAUD_MID	=	BAUD_END/2 - 1;

reg	[7:0]			tx_data_reg;
// reg					tx_flag;
reg	[12:0]			baud_cnt;
reg					bit_flag;
reg	[3:0]			bit_cnt;


always @(posedge clk or negedge rstn) begin
	if (rstn == 1'b0)
		tx_data_reg <= 'b0;
	if (tx_trig == 1'b1)
		tx_data_reg <= tx_data;
	else if (bit_flag == 1'b1 && bit_cnt != 'b0)
		tx_data_reg = tx_data_reg >> 1;
end

// always @(posedge clk or negedge rstn) begin
// 	if (rstn == 1'b0)
// 		tx_flag <= 1'b0;
// 	else if (bit_cnt == 'd8 && baud_cnt == BAUD_END)
// 		tx_flag <= 1'b0;
// 	else if (tx_trig == 1'b1 && bit_cnt == 1'b0)
// 		tx_flag <= 1'b1;
// end

always @(posedge clk or negedge rstn) begin
	if (rstn == 1'b0)
		baud_cnt <= 'b0;
	else if (baud_cnt == BAUD_END)
		baud_cnt <= 'b0;
	else if (tx_busy == 1'b1)
		baud_cnt <= baud_cnt + 1'b1;
end

always @(posedge clk or negedge rstn) begin
	if (rstn == 1'b0)
		bit_flag <= 1'b0;
	else if (baud_cnt == BAUD_END)
		bit_flag <= 1'b1;
	else
		bit_flag <= 1'b0;
end

always @(posedge clk or negedge rstn) begin
	if (rstn == 1'b0)
		bit_cnt <= 'b0;
	else if (bit_flag == 1'b1 && bit_cnt == BIT_END)
		bit_cnt <= 'b0;
	else if (bit_flag == 1'b1)
		bit_cnt <= bit_cnt + 1'b1;
end

always @(posedge clk or negedge rstn) begin
	if (rstn == 1'b0)
		tx <= 1'b1;
	else if (tx_busy == 1'b1 && bit_cnt == 1'b0)
		tx <= 1'b0;
	else if (tx_busy == 1'b1 && bit_cnt == BIT_END)
		tx <= 1'b1;
	else if (tx_busy == 1'b1)
		tx <= tx_data_reg[0];
	else
		tx <= 1'b1;
end

always @(posedge clk or negedge rstn) begin
	if (rstn == 1'b0)
		tx_busy <= 1'b0;
	else if (tx_trig && !tx_busy)
		tx_busy <= 1'b1;
	else if (bit_cnt == BIT_END && bit_flag)
		tx_busy <= 1'b0;
end

endmodule