module sdram_aref (
	input					sclk,
	input					srst_n,
	input					aref_en,
	output	reg	[ 3:0]		sdram_cmd,
	output		[11:0]		sdram_addr,
	output					flag_aref_ask,
	output					flag_aref_end
);

localparam	AREF_CNT_END	=	749;
localparam	CMD_CNT_END		=	10;
localparam	NOP				=	4'b0111;
localparam	PREC			=	4'b0010;
localparam	AREF			=	4'b0001;

reg		[ 9:0]			aref_cnt;
reg		[ 3:0]			cmd_cnt;


always @(posedge sclk or negedge srst_n) begin
	if (!srst_n)
		aref_cnt <= 'd0;
	else if (aref_en)
		aref_cnt <= 'd0;
	else if (aref_cnt != AREF_CNT_END)
		aref_cnt <= aref_cnt + 1'd1;
end

always @(posedge sclk or negedge srst_n) begin
	if (!srst_n)
		cmd_cnt <= 'd0;
	else if (!aref_en)
		cmd_cnt <= 'd0;
	else if (cmd_cnt != CMD_CNT_END)
		cmd_cnt	<= cmd_cnt + 1'd1;
end

always @(cmd_cnt) begin
	case (cmd_cnt)
		1: sdram_cmd = PREC;
		2: sdram_cmd = AREF;
		6: sdram_cmd = AREF;
		default: sdram_cmd = NOP;
	endcase
end

assign		flag_aref_ask	=	aref_cnt == AREF_CNT_END;
assign		sdram_addr 		=	12'b0100_0000_0000;
assign		flag_aref_end	=	cmd_cnt	==	CMD_CNT_END;

endmodule //sdram_aref
