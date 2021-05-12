module gauss_filter #(
  parameter int PIX_DATA_W    = 12,
  parameter int WINDOW_SIZE   = 7,
  parameter int INPUTS_AMOUNT = WINDOW_SIZE ** 2
)(
  input                                             rst_i,
  input                                             clk_i,

  input                                             data_valid_i,
  input [INPUTS_AMOUNT - 1 : 0][PIX_DATA_W - 1 : 0] data_i,

  output                                            data_valid_o,
  output [PIX_DATA_W - 1 : 0]                       data_o
);

logic [17 : 0] MAIN_3_COEF [8 : 0]  = '{ 'd1, 'd2, 'd1,
                                         'd2, 'd4, 'd2,
                                         'd1, 'd2, 'd1 };
logic [17 : 0] MAIN_5_COEF [24 : 0] = '{ 'd1, 'd4,  'd6,  'd4,  'd1,
                                         'd4, 'd16, 'd24, 'd16, 'd4,
                                         'd6, 'd24, 'd36, 'd24, 'd6,
                                         'd4, 'd16, 'd24, 'd16, 'd4,
                                         'd1, 'd4,  'd6,  'd4,  'd1 };
logic [17 : 0] MAIN_7_COEF [48 : 0] = '{ 'd1,  'd6,   'd15,  'd20,  'd15,  'd6,   'd1,
                                         'd6,  'd36,  'd90,  'd120, 'd90,  'd36,  'd6,
                                         'd15, 'd90,  'd225, 'd300, 'd225, 'd90,  'd15,
                                         'd20, 'd120, 'd300, 'd400, 'd300, 'd120, 'd20,
                                         'd15, 'd90,  'd225, 'd300, 'd225, 'd90,  'd15,
                                         'd6,  'd36,  'd90,  'd120, 'd90,  'd36,  'd6,
                                         'd1,  'd6,   'd15,  'd20,  'd15,  'd6,   'd1   };

localparam int NORM_3_VAL = 4;
localparam int NORM_5_VAL = 8;
localparam int NORM_7_VAL = 12;

logic valid;
logic add_valid;
logic data_tmp_valid;

function automatic int calc_mul_width(
  int win_size
);
  int mul_width;

  if( WINDOW_SIZE == 3 )
    mul_width = 2;
  else
    if( WINDOW_SIZE == 5 )
      mul_width = 6;
    else
      if( WINDOW_SIZE == 7 )
        mul_width = 9;

  return mul_width;
endfunction : calc_mul_width

localparam int MUL_WIDTH          = calc_mul_width( WINDOW_SIZE );
localparam int MUL_PIX_DATA_WIDTH = PIX_DATA_W          + MUL_WIDTH;
localparam int SUM_WIDTH          = MUL_PIX_DATA_WIDTH  + $clog2( INPUTS_AMOUNT );

logic [INPUTS_AMOUNT - 1 : 0][MUL_PIX_DATA_WIDTH - 1 : 0] data_tmp, data_tmp_2;
logic [SUM_WIDTH - 1 : 0]             sum_data_temp;
logic [PIX_DATA_W - 1 : 0]            data;

always_ff @( posedge clk_i )
  for( int i = 0; i < INPUTS_AMOUNT; i++ )
    if( WINDOW_SIZE == 3 )
      data_tmp[i] <= data_i[i] * MAIN_3_COEF[i];
    else
      if( WINDOW_SIZE == 5 )
        data_tmp[i] <= data_i[i] * MAIN_5_COEF[i];
      else
        if( WINDOW_SIZE == 7 )
          data_tmp[i] <= data_i[i] * MAIN_7_COEF[i];

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_tmp_valid <= 1'b0;
  else
    data_tmp_valid <= data_valid_i;

always_ff @( posedge clk_i )
  if( WINDOW_SIZE == 3 )
    data <= PIX_DATA_W'( sum_data_temp >> NORM_3_VAL );
  else
    if( WINDOW_SIZE == 5 )
      data <= PIX_DATA_W'( sum_data_temp >> NORM_5_VAL );
    else
      if( WINDOW_SIZE == 7 )
        data <= PIX_DATA_W'( sum_data_temp >> NORM_7_VAL );

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    valid <= 1'b0;
  else
    valid <= add_valid;

assign data_valid_o = valid;
assign data_o = data;

pipeline_adder #(
  .NUMBERS_AMOUNT ( INPUTS_AMOUNT       ),
  .NUMBER_WIDTH   ( MUL_PIX_DATA_WIDTH  )
) pipeline_adder (
  .rst_i          ( rst_i         ),
  .clk_i          ( clk_i         ),

  .data_valid_i   ( data_tmp_valid),
  .data_i         ( data_tmp      ),

  .data_valid_o   ( add_valid     ),
  .data_o         ( sum_data_temp )
);

endmodule : gauss_filter
