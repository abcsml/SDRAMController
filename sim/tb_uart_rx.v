`timescale 1ns/1ns

module tb_uart_rx;

reg					clk;
reg					rst;
reg					tx;

wire				po_flag;
wire	[7:0]		rx_data;

reg		[7:0]		mem_a[3:0];

initial begin
	clk		<=		1;
	rst		<=		0;
	tx		<=		1;
	#100
	rst		<=		1;
	#100
	tx_byte();
end

always	#5		clk		=		~clk;

initial $readmemh("./tx_data.txt", mem_a);

task		tx_byte();
	integer	i;
	for(i = 0; i < 4; i = i + 1) begin
		tx_bit(mem_a[i]);
	end
endtask

task		tx_bit(
	input	[7:0]		data
);
	integer i;
	for (i = 0; i < 10; i = i + 1) begin
		case (i)
			0:		tx		<=		1'b0;
			1:		tx		<=		data[0];
			2:		tx		<=		data[1];
			3:		tx		<=		data[2];
			4:		tx		<=		data[3];
			5:		tx		<=		data[4];
			6:		tx		<=		data[5];
			7:		tx		<=		data[6];
			8:		tx		<=		data[7];
			9:		tx		<=		1'b1;
		endcase
		#560;
	end
endtask

uart_rx		uart_rx_inst(
	.clk				(clk			),
	.rst				(rst			),
	.rx					(tx				),
	.rx_data			(rx_flag		),
	.po_flag			(po_flag		)
);

endmodule
