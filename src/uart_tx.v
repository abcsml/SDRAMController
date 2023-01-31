module uart_tx(
	input				clk,
	input				rst,
	output	reg			tx,
	input				tx_trig,
	input	[7:0]		tx_data
);

localparam	FPGA_FREQ	=	50_000_000;
localparam	BAUD_RATE	=	9600;
localparam	BIT_END		=	8;

`ifndef SIM
localparam	BAUD_END	=	(1/BAUD_RATE)*FPGA_FREQ;
`else
localparam	BAUD_END	=	56;
`endif

localparam	BAUD_MID	=	BAUD_END/2 - 1;

reg	[7:0]			tx_data_reg;
reg					tx_flag;
reg	[12:0]			baud_cnt;
reg					bit_flag;
reg	[3:0]			bit_cnt;




endmodule