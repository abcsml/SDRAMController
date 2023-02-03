module sdram_init (
	input					sclk,	// 20ns
	input					rstn,
	output	reg	[ 3:0]		cmd_reg,
	output	reg	[11:0]		sdram_addr,
	output	reg				flag_init_end
);

// Parameter and Internal Signals
localparam	CNT_200US_END	=	10000;
// SDRAM Cmd
localparam	NOP				=	4'b0111;
localparam	PREC			=	4'b0010;
localparam	AREF			=	4'b0001;
localparam	MSET			=	4'b0000;

reg	[13:0]			cnt_200us;
reg					flag_200us;
reg	[ 3:0]			cnt_cmd;

// Main Code
always @(posedge sclk or negedge rstn) begin
	if (rstn == 1'b0)
		cnt_200us <= 'b0;
	else if (cnt_200us != CNT_200US_END)
		cnt_200us <= cnt_200us + 1'b1;
end

always @(posedge sclk or negedge rstn) begin
	if (rstn == 1'b0)
		flag_200us <= 1'b0;
	else if (cnt_200us == CNT_200US_END)
		flag_200us <= 1'b1;
end

always @(posedge sclk or negedge rstn) begin
	if (rstn == 1'b0)
		cnt_cmd <= 1'b0;
	else if (flag_200us == 1'b1 && cnt_cmd != 'd10)
		cnt_cmd <= cnt_cmd + 1'b1;
end

always @(posedge sclk or negedge rstn) begin
	if (rstn == 1'b0)
		cmd_reg <= NOP;
	else if (flag_200us == 1'b1 && cnt_cmd == 'b0)
		cmd_reg <= PREC;
	else if (cnt_cmd == 'b1)
		cmd_reg <= AREF;
	else if (cnt_cmd == 'd5)
		cmd_reg <= AREF;
	else if (cnt_cmd == 'd9)
		cmd_reg <= MSET;
	else
		cmd_reg <= NOP;
end

always @(posedge sclk or negedge rstn) begin
	if (rstn == 1'b0)
		sdram_addr <= 'd0;
	else if (flag_200us == 1'b1)
		case (cnt_cmd)
			0:	sdram_addr <= 12'b0100_0000_0000;
			9:	sdram_addr <= 12'b0000_0011_0010;
			default:	sdram_addr <= 'd0;
		endcase
end

always @(posedge sclk or negedge rstn) begin
	if (rstn == 1'b0)
		flag_init_end <= 1'b0;
	else if (cnt_cmd == 'd10)
		flag_init_end <= 1'b1;
end

endmodule
