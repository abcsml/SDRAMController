module top (
    input                   sclk,
    input                   srst_n,

    input                   rs232_rx,
    output                  rs232_tx
);

// uart
wire 	                po_flag;
wire            [ 7:0]  rx_data;
wire 	                tx_trig;
wire 	        [ 7:0]  tx_data;

// cmd decode
wire 	                wr_trig;
wire 	                rd_trig;
wire 	                wfifo_wr_en;

// fifo
wire            [ 7:0]  wfifo_dout;
wire 	                wfifo_rd_en;
wire            [ 7:0]  rfifo_dout;
wire 	                rfifo_wr_en;
wire 	                rfifo_rd_en;

// sdram
wire            [ 7:0]  rd_data;
// wire 	sdram_clk;
// wire 	sdram_cke;
// wire 	sdram_cs_n;
// wire [1:0]	sdram_bank;
// wire [11:0]	sdram_addr;
// wire 	sdram_ras_n;
// wire 	sdram_cas_n;
// wire 	sdram_we_n;
// wire [1:0]	sdram_dqm;
// wire 	wr_data_en;

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
	.tx_trig 		    (tx_trig 		    ),////
	.tx_data 		    (tx_data 		    )////
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
    .rst                (srst_n             ),
    .din                (rx_data            ),
    .wr_en              (wfifo_wr_en        ),
    .rd_en              (wfifo_rd_en        ),
    .dout               (wfifo_dout         ),
    .full               (full               ),
    .empty              (empty              )
);

fifo_512x8 rfifo_inst (
    .clk                (sclk               ),
    .rst                (srst_n             ),
    .din                (rd_data            ),
    .wr_en              (rfifo_wr_en        ),
    .rd_en              (rfifo_rd_en        ),
    .dout               (dout               ),////
    .full               (full               ),
    .empty              (empty              )
);

sdram_top sdram_top_inst(
	//ports
	.sclk        		(sclk        		),
	.srst_n      		(srst_n      		),
	.wr_trig     		(wr_trig     		),
	.wr_len      		(1      		    ),
	.wr_data     		(wfifo_dout     	),
	.wr_addr     		(wr_addr     		),///////
	.wr_data_en  		(wfifo_rd_en  		),
	.rd_trig     		(rd_trig     		),
	.rd_len      		(1            		),
	.rd_addr     		(rd_addr     		),//////
	.rd_data     		(rd_data     		),
	.rd_data_en  		(rfifo_wr_en  		),
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
