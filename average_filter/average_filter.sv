module average_filter #(
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

localparam int SUM_WIDTH = PIX_DATA_W + $clog2( INPUTS_AMOUNT );

logic                       add_data_valid;
logic [SUM_WIDTH - 1 : 0]   add_data;

pipeline_adder #(
  .NUMBERS_AMOUNT ( INPUTS_AMOUNT   ),
  .NUMBER_WIDTH   ( PIX_DATA_W      )
) pipeline_adder (
  .rst_i          ( rst_i           ),
  .clk_i          ( clk_i           ),
  
  .data_valid_i   ( data_valid_i    ),
  .data_i         ( data_i          ),

  .data_valid_o   ( add_data_valid  ),
  .data_o         ( add_data        )
);

lut_divider #(
  .DIVIDEND_W ( SUM_WIDTH       ),
  .QUOTIENT_W ( PIX_DATA_W      ),
  .DIVISOR    ( INPUTS_AMOUNT   )
) lut_divider (
  .rst_i      ( rst_i           ),
  .clk_i      ( clk_i           ),

  .valid_i    ( add_data_valid  ),
  .dividend_i ( add_data        ),

  .valid_o    ( data_valid_o    ),
  .quotient_o ( data_o          )
);

endmodule : average_filter
