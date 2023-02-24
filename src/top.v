module top (
    input                   sclk,
    input                   srst_n,

    // uart
    input                   rs232_rx,
    output                  rs232_tx,

    // sdram
	output	wire			sdram_clk,
	output	wire			sdram_cke,
	output	wire			sdram_cs_n,
	output	wire	[ 1:0]	sdram_bank,
	output	wire	[11:0]	sdram_addr,
	output	wire			sdram_ras_n,
	output	wire			sdram_cas_n,
	output	wire			sdram_we_n,
	output	wire	[ 1:0]	sdram_dqm,
	inout			[15:0]	sdram_dq
);

reg             [20:0]  wr_addr_cur;
reg             [20:0]  rd_addr_cur;

// uart
wire 	                po_flag;
wire            [ 7:0]  rx_data;
reg 	                tx_trig;
wire 	        [ 7:0]  tx_data;
wire                    tx_busy;

// cmd decode
wire 	                wr_trig;
wire 	                rd_trig;
wire 	                wfifo_wr_en;

// fifo
wire            [ 7:0]  wfifo_dout;
wire            [ 7:0]  rfifo_dout;
wire 	                rfifo_rd_en;

wire                    wfifo_empty;
wire                    wfifo_full;
wire                    rfifo_empty;
wire                    rfifo_full;

// sdram
wire            [15:0]  rd_data;
wire 	                wfifo_rd_en;
wire 	                rfifo_wr_en;

assign  rfifo_rd_en =   !rfifo_empty && !tx_busy && !tx_trig;

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
		tx_trig <= 1'b0;
	else
		tx_trig <= rfifo_rd_en;
end

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        wr_addr_cur <= 'd0;
    else if (wr_trig)
        wr_addr_cur <= wr_addr_cur + 'd4;
end

always @(posedge sclk or negedge srst_n) begin
    if (!srst_n)
        rd_addr_cur <= 'd0;
    else if (rd_trig)
        rd_addr_cur <= rd_addr_cur + 'd4;
end

uart_rx uart_rx_inst(
	.clk     		    (sclk     		    ),
	.rst     		    (srst_n     		),
	.rx      		    (rs232_rx      		),
	.rx_data 		    (rx_data 		    ),
	.po_flag 		    (po_flag 		    )
);

uart_tx uart_tx_inst(
	.clk     		    (sclk     		    ),
	.rstn    		    (srst_n    		    ),
	.tx      		    (rs232_tx      		),
	.tx_trig 		    (tx_trig 		    ),
	.tx_data 		    (rfifo_dout 		),
    .tx_busy            (tx_busy            )
);

cmd_decode cmd_decode_inst(
	.sclk        		(sclk        		),
	.srst_n      		(srst_n      		),
	.uart_flag   		(po_flag   		    ),
	.uart_data   		(rx_data   		    ),
	.wr_trig     		(wr_trig     		),
	.rd_trig     		(rd_trig     		),
	.wfifo_wr_en 		(wfifo_wr_en 		)
);

fifo_512x8 wfifo_inst (
    .clk                (sclk               ),
    .rst                (!srst_n            ),
    .din                (rx_data            ),
    .wr_en              (wfifo_wr_en        ),
    .rd_en              (wfifo_rd_en        ),
    .dout               (wfifo_dout         ),
    .full               (wfifo_full         ),
    .empty              (wfifo_empty        )
);

fifo_512x8 rfifo_inst (
    .clk                (sclk               ),
    .rst                (!srst_n            ),
    .din                (rd_data[7:0]	    ),
    .wr_en              (rfifo_wr_en        ),
    .rd_en              (rfifo_rd_en        ),
    .dout               (rfifo_dout         ),
    .full               (rfifo_full         ),
    .empty              (rfifo_empty        )
);

sdram_top sdram_top_inst(
	//ports
	.sclk        		(sclk        		),
	.srst_n      		(srst_n      		),
	.wr_trig     		(wr_trig     		),
	.wr_len      		(1      		    ),
	.wr_data     		({8'd0, wfifo_dout} ),
	.wr_addr     		(wr_addr_cur        ),
	.wr_data_en  		(wfifo_rd_en  		),
	.rd_trig     		(rd_trig     		),
	.rd_len      		(1            		),
	.rd_addr     		(rd_addr_cur     	),
	.rd_data     		(rd_data     		),
	.rd_data_en  		(rfifo_wr_en  		),
	.sdram_clk			(sdram_clk			),
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

endmodule //top
