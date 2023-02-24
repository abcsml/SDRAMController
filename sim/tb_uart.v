`timescale 1ns/1ns

module tb_uart;

reg					clk;
reg					rstn;
reg					tx_trig;

wire				tx;
wire				tx_busy;
reg		[7:0]		tx_data;

wire				po_flag;
wire	[7:0]		rx_data;

reg		[7:0]		mem_a[3:0];

initial begin
	clk		<=		1;
	rstn	<=		0;
	tx_trig	<=		0;
	tx_data	<=		0;
	#100
	rstn	<=		1;
	#100
	tx_byte();
end

always	#10		clk		=		~clk;

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
	begin
		tx_data <= data;
		tx_trig <= 1'b1;
		#20;
		tx_trig <= 1'b0;
		tx_data <= 'b0;
		#16000;
	end
endtask

uart_rx		uart_rx_inst(
	.clk				(clk			),
	.rst				(rstn			),
	.rx					(tx				),
	.rx_data			(rx_data		),
	.po_flag			(po_flag		)
);

uart_tx		uart_tx_inst(
	.clk				(clk			),
	.rstn				(rstn			),
	.tx					(tx				),
	.tx_trig			(tx_trig		),
	.tx_data			(tx_data		),
	.tx_busy			(tx_busy		)
);

endmodule
