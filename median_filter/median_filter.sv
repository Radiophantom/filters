module median_filter #(
  parameter int PIX_DATA_W    = 12,
  parameter int WINDOW_SIZE   = 3,
  parameter int INPUTS_AMOUNT = WINDOW_SIZE ** 2
)(
  input                                               rst_i,
  input                                               clk_i,

  input                                               data_valid_i,
  input   [INPUTS_AMOUNT - 1 : 0][PIX_DATA_W - 1 : 0] data_i,

  output                                              data_valid_o,
  output  [PIX_DATA_W - 1 : 0]                        data_o
);

logic [INPUTS_AMOUNT - 1 : 0][PIX_DATA_W - 1 : 0] data_tmp;

sorting_network #(
  .NUMBER_WIDTH   ( PIX_DATA_W    ),
  .NUMBERS_AMOUNT ( INPUTS_AMOUNT )
) sorting_network (
  .rst_i          ( rst_i         ),
  .clk_i          ( clk_i         ),

  .data_valid_i   ( data_valid_i  ),
  .data_i         ( data_i        ),

  .data_valid_o   ( data_valid_o  ),
  .data_o         ( data_tmp      )
);

assign data_o = data_tmp[INPUTS_AMOUNT / 2];

endmodule : median_filter
