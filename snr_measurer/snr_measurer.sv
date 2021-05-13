module snr_measurer #(
  parameter int PIX_DATA_W    = 12,
  // full sensor frame parameters
  parameter int FRAME_HEIGHT        = 1125,
  parameter int FRAME_WIDTH         = 2200,
  // image parameters
  parameter int BLACK_HEIGHT        = 10,
  // image coordinates
  parameter int ROW_START_OFFSET    = 1,   // first valid row number
  parameter int SUM_W               = $clog2( BLACK_HEIGHT + FRAME_WIDTH )
)(
  input                       rst_i,
  input                       clk_i,

  input                       pix_valid_i,
  input  [PIX_DATA_W - 1 : 0] pix_data_i,

  input                       hd_i,
  input                       vd_i,

  output                      snr_valid_o,
  output [PIX_DATA_W - 1 : 0] snr_data_o
);

always_ff @( posedge clk_i )
  if( vd_stb )
    row_offset_cnt <= '0;
  else
    if( hd_stb )
      row_offset_cnt <= row_offset_cnt + 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    prev_valid <= 1'b0;
  else
    prev_valid <= pix_valid_i;

assign row_start_stb = pix_valid_i  && !prev_valid;
assign row_end_stb   = !pix_valid_i && prev_valid;

always_ff @( posedge clk_i )
  row_valid <= ( row_offset_cnt >= ROW_START_OFFSET ) && ( row_offset_cnt <= ( ROW_START_OFFSET + IMAGE_HEIGHT ) );

assign start_stb  = row_start_stb && ( row_offset_cnt == ROW_START_OFFSET );
assign stop_stb   = row_end_stb   && ( row_offset_cnt == ( ROW_START_OFFSET + BLACK_HEIGHT ) );

logic [63 : 0] sum;

always_ff @( posedge clk_i )
  if( cum_cnt_rst )
    cum_sum <= '0;
  else
    if( cum_cnt_en )
      cum_sum <= cum_sum + pix_data_i;


function automatic logic [17 : 0] divider(
  int divisor
);
  
  real tmp_div = 1 / divisor;
  logic tmp_bin;

  while( tmp_div != 1.0 )
    begin
      if( loop == 18 )
        break;
      tmp_div = tmp_div * 2;
      if( tmp_div >= 1.0 )
        begin
          tmp_bin = 1'b1;
          tmp_div = tmp_div - 1.0;
        end
      else
        begin
          tmp_bin = 1'b0;
          tmp_div = tmp_div;
        end
      divider = { divider[16 : 0], tmp_bin };
    end

    return divider;

endfunction : divider

always_ff @( posedge clk_i )
  if( div_en )
    average_value <= cum_sum * div_coef;

logic signed [12 : 0] diff_val;

always_ff @( posedge clk_i )
  if( sub_en )
    diff_val <= average_value - pix_data_i;

always_ff @( posedge clk_i )
  if( diff_val < 0 )
    pos_diff_val <= -diff_val;
  else
    pos_diff_val <= diff_val;

always_ff @( posedge clk_i )
  if( exp_cnt_rst )
    exp_sum <= '0;
  else
    if( exp_cnt_en )
      exp_sum <= exp_sum + abs( diff_val * diff_val );

always_ff @( posedge clk_i )

assign data_valid = row_valid && column_valid;

endmodule : snr_measurer

