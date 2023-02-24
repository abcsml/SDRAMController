`timescale 1ns/1ns

module tb_top;

localparam  DLEN    =   38;

reg					sclk;
reg					srst_n;

// Parameter and Internal Signals
reg					tx_trig;
wire				rs232_tx;
wire				tx_busy;
reg		[7:0]		tx_data;

wire				rs232_rx;
wire				po_flag;
wire	[7:0]		rx_data;

wire				sdram_clk;
wire				sdram_cke;
wire				sdram_cs_n;
wire [ 1:0]			sdram_bank;
wire [11:0]			sdram_addr;
wire				sdram_ras_n;
wire				sdram_cas_n;
wire				sdram_we_n;
wire [ 1:0]			sdram_dqm;
wire [15:0]			sdram_dq;

reg		[7:0]		mem_a[DLEN-1:0];

initial begin
	sclk    =   1;
	srst_n  =   0;
	tx_trig	=   0;
	tx_data	=	0;
	#100
	srst_n  =   1;
	#200000
	tx_byte();
end

initial $readmemh("./tx_data.txt", mem_a);

always	#10		sclk = ~ sclk;

always @(posedge sclk) begin
	if (po_flag)
		$display("recv data: %x", rx_data);
end


task tx_byte();
	integer	i;
	for(i = 0; i < DLEN; i = i + 1) begin
		tx_bit(mem_a[i]);
	end
endtask

task tx_bit(
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


uart_rx	uart_rx_inst(
	.clk				(sclk			),
	.rst				(srst_n			),
	.rx					(rs232_rx		),
	.rx_data			(rx_data		),
	.po_flag			(po_flag		)
);

uart_tx	uart_tx_inst(
	.clk				(sclk			),
	.rstn				(srst_n			),
	.tx					(rs232_tx		),
	.tx_trig			(tx_trig		),
	.tx_data			(tx_data		),
	.tx_busy			(tx_busy		)
);

top top_inst(
	.sclk        		(sclk        		),
	.srst_n      		(srst_n      		),
	.rs232_rx    		(rs232_tx    		),
	.rs232_tx    		(rs232_rx    		),
	.sdram_clk   		(sdram_clk   		),
	.sdram_cke   		(sdram_cke   		),
	.sdram_cs_n  		(sdram_cs_n  		),
	.sdram_bank  		(sdram_bank  		),
	.sdram_addr  		(sdram_addr  		),
	.sdram_ras_n 		(sdram_ras_n 		),
	.sdram_cas_n 		(sdram_cas_n 		),
	.sdram_we_n  		(sdram_we_n  		),
	.sdram_dqm   		(sdram_dqm   		),
	.sdram_dq    		(sdram_dq    		)
);

sdram_model_plus #(
	.addr_bits     		(12          		),
	.data_bits     		(16          		),
	.col_bits      		(9           		),
	.mem_sizes     		(2*1024*1024 		))
sdram_model_plus_inst (
	.Dq    				(sdram_dq			),
	.Addr  				(sdram_addr			),
	.Ba    				(sdram_bank			),
	.Clk   				(sdram_clk			),
	.Cke   				(sdram_cke			),
	.Cs_n  				(sdram_cs_n			),
	.Ras_n 				(sdram_ras_n		),
	.Cas_n 				(sdram_cas_n		),
	.We_n  				(sdram_we_n			),
	.Dqm   				(sdram_dqm			),
	.Debug 				(1'b0				)
);

endmodule

