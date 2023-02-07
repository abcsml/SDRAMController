module sdram_top (
	input					sclk,
	input					srst_n,
	// SDRAM
	output	wire			sdram_clk,
	output	wire			sdram_cke,
	output	wire			sdram_cs_n,
	output	wire	[ 1:0]	sdram_bank,
	output	reg		[11:0]	sdram_addr,
	output	wire			sdram_ras_n,
	output	wire			sdram_cas_n,
	output	wire			sdram_we_n,
	output	wire	[ 1:0]	sdram_dqm,
	inout			[15:0]	sdram_dq
);
/****************************************
* Parameter and Internal Signals
****************************************/
// state
localparam	S_IDLE	=	3'd0;
localparam	S_ARBIT	=	3'd1;
localparam	S_AREF	=	3'd2;

reg		[ 1:0]			state;

reg		[ 3:0]			sdram_cmd;
// init SDRAM
wire					flag_init_end;
wire	[ 3:0]			init_cmd;
wire	[11:0]			init_addr;
// auto refresh SDRAM
wire					aref_en;
wire					flag_aref_ask;
wire					flag_aref_end;
wire	[ 3:0]			aref_cmd;
wire	[11:0]			aref_addr;


/***************************************
* Main Code
***************************************/
assign	sdram_clk	=	~sclk;		// ？
assign	sdram_cke	=	1'b1;
assign	sdram_dqm	=	2'b00;		// 令DQ无效

assign	{sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n}	=	sdram_cmd;

always @(posedge sclk or negedge srst_n) begin
	if (!srst_n)
		state <= S_IDLE;
	else case (state)
		S_IDLE: state <= flag_init_end ? S_ARBIT : S_IDLE;
		S_ARBIT: state <= flag_aref_ask ? S_AREF : S_ARBIT;
		S_AREF: state <= flag_aref_end ? S_ARBIT : S_AREF;
		default: state <= S_IDLE;
	endcase
end

always @(*) begin
	case (state)
		S_IDLE: begin
			sdram_cmd 	=	init_cmd;
			sdram_addr	=	init_addr;
		end
		S_AREF: begin
			sdram_cmd 	=	aref_cmd;
			sdram_addr	=	aref_addr;
		end
		default: begin
			sdram_cmd 	=	4'b0111;
			sdram_addr	=	'd0;
		end
	endcase
end

assign	aref_en		=	state == S_AREF;

sdram_init	sdram_init_inst(
	.sclk				(sclk			),
	.rstn				(srst_n			),
	.cmd_reg			(init_cmd		),
	.sdram_addr			(init_addr		),
	.flag_init_end		(flag_init_end	)
);

sdram_aref sdram_aref_inst(
	.sclk          		(sclk          	),
	.srst_n        		(srst_n        	),
	.aref_en       		(aref_en       	),
	.sdram_cmd     		(aref_cmd     	),
	.sdram_addr    		(aref_addr    	),
	.flag_aref_ask 		(flag_aref_ask 	),
	.flag_aref_end 		(flag_aref_end 	)
);

endmodule
