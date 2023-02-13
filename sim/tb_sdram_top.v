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
wire [15:0]			sdram_dq;

reg                 wr_trig;
reg  [ 7:0]         wr_len;
reg  [15:0]         wr_data;
reg  [20:0]         wr_addr;
wire               	wr_data_en;

initial begin
	sclk = 1;
	srst_n = 0;
	#100
	srst_n = 1;
	wr_trig	= 1;
	wr_len = 0;
	wr_data = 0;
	wr_addr = 0;
	#200000
	write();
end

always	#10		sclk = ~ sclk;

task write();
	begin
		wr_trig	<=	1'b1;
		wr_len	<=	'd1000;
		wr_data	<=	'hdd;
		wr_addr	<=	'b1000_111_111_111;
		#20
		wr_trig	<=	1'b0;
	end
endtask

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
	.sdram_dq    		(sdram_dq    		),

	.wr_trig			(wr_trig			),
	.wr_len				(wr_len				),
	.wr_data			(wr_data			),
	.wr_addr			(wr_addr			),
	.wr_data_en			(wr_data_en			)
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
