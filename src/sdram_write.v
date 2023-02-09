module sdram_write(
	input					sclk,
	input					srst_n,
	// Control
	input					wr_en,
	output	reg				flag_wr_ask,
	output	reg				flag_wr_end,
	// Other
	input					wr_trig,
	input		[ 7:0]		wr_len,
	input					wr_data,
	output	reg				wr_data_en,
	output		[ 3:0]		sdram_cmd,
	output		[11:0]		sdram_addr
);

reg						flag_wring;
reg						flag_act_end;
reg						flag_pre_end;

reg	[ 2:0]				state;
reg						wr_row;
reg	[ 1:0]				burst_cnt;
reg	[ 7:0]				rem_burst_len;


endmodule //sdram_write
