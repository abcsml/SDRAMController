`define SIM

module uart_rx
	input					clk,
	input					rst,
	input					rx,
	output	reg	[7:0]		rx_data,
	output	reg				po_flag

// Parameter and Internal Signals
localparam	FPGA_FREQ	=	50_000_000;
localparam	BAUD_RATE	=	9600;
localparam	BIT_END		=	8;

`ifndef SIM
localparam	BAUD_END	=	(1/BAUD_RATE)*FPGA_FREQ;
`else
localparam	BAUD_END	=	56;
`endif

localparam	BAUD_MID	=	BAUD_END/2 - 1;

reg					rx1;
reg					rx2;
reg					rx3;
reg					rx_flag;
reg	[12:0]			baud_cnt;
reg					bit_flag;
reg	[3:0]			bit_cnt;

wire				rx_neg;

// Main code
assign	rx_neg	=		~rx2 & rx3;

always @(posedge clk) begin
	rx1		<=		rx;
	rx2		<=		rx1;
	rx3		<=		rx2;
end

always @(posedge clk or negedge rst) begin	// 异步复位
	if (rst == 1'b0)
		rx_flag	<=	1'b0;
	else if (rx_neg == 1'b1)
		rx_flag	<=	1'b0;
	else if (bit_cnt == 'd0 && baud_cnt == BAUD_END)
		rx_flag	<=	1'b1;
end

always @(posedge clk) begin
	if (rx_flag == 1'b1 && baud_cnt != BAUD_END)
		baud_cnt <= baud_cnt + 'b1;
	else
		baud_cnt <= 'b0;
end

always @(posedge clk) begin
	if (baud_cnt == BAUD_MID)
		bit_flag <= 1'b1;
	else
		bit_flag <= 1'b0;
end

always @(posedge clk) begin
	if (bit_flag == 1'b1 && bit_cnt != BIT_END)
		bit_cnt <= bit_cnt + 1'b1;
	else
		bit_cnt <= 1'b0;
end

always @(posedge clk or negedge rst) begin
	if (rst == 1'b0)
		rx_data <= 'b0;
	else if (bit_cnt != 'b0 && bit_flag == 1'b1)
		rx_data <= {rx2, rx_data[7:1]};
end

always @(posedge clk) begin
	if (bit_cnt == BIT_END && bit_flag == 1'b1)
		po_flag <= 1'b1;
	else
		po_flag <= 1'b0;
end

endmodule
