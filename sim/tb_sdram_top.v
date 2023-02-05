`timescale 1ns/1ns

module tb_sdram_top;

reg					sclk;
reg					srst_n;

// Parameter and Internal Signals
wire				sdram_clk;
wire				sdram_cke;
wire				sdram_cs_n;
wire [ 1:0]			sdram_bank;
wire [11:0]			sdram_addr;
wire				sdram_ras_n;
wire				sdram_cas_n;
wire				sdram_we_n;
wire [ 1:0]			sdram_dqm;

initial begin
	sclk = 1;
	srst_n <= 0;
	#100
	srst_n <= 1;
end

always	#10		sclk = ~ sclk;


sdram_top sdram_top_inst (
	.sclk        		(sclk        		),
	.srst_n      		(srst_n      		),
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
u_sdram_model_plus(
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
	.Debug 				(1'b1				)
);


endmodule
