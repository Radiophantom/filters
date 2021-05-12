module window_buffer #(
	parameter int PIX_DATA_W          = 12,
	parameter int WINDOW_SIZE         = 3,
  parameter int WINDOW_PIX_AMOUNT   = WINDOW_SIZE ** 2,
  // full sensor frame parameters
  parameter int FRAME_HEIGHT        = 1125,
  parameter int FRAME_WIDTH         = 2200,
  // image parameters
  parameter int IMAGE_HEIGHT        = 1096,
  parameter int IMAGE_WIDTH         = 1936,
  // image coordinates
  parameter int ROW_START_OFFSET    = 20, // first valid row number
  parameter int COLUMN_START_OFFSET = 50 // first valid pixel number in a row
)(
	input                                                rst_i,
	input                                                clk_i,

	input                                                hd_stb,
	input                                                vd_stb,

	input  [PIX_DATA_W - 1 : 0]                          pix_data_i,

  output                                               win_valid_o,
	output [WINDOW_PIX_AMOUNT - 1 : 0][PIX_DATA_W - 1 : 0]  win_data_o
);

localparam int PIX_ADDR_W   = $clog2( IMAGE_WIDTH   );

localparam int ROW_CNT_W    = $clog2( FRAME_HEIGHT  );
localparam int COLUMN_CNT_W = $clog2( FRAME_WIDTH   );

localparam int RAM_AMOUNT   = WINDOW_SIZE - 1;

logic                                         wr_pix_en;
logic [PIX_ADDR_W - 1 : 0]                    wr_pix_addr;
logic [RAM_AMOUNT - 1 : 0][PIX_DATA_W - 1 : 0]                    wr_pix_data;

logic                                         rd_pix_en;
logic [PIX_ADDR_W - 1 : 0]                    rd_pix_addr;
logic [RAM_AMOUNT - 1 : 0][PIX_DATA_W - 1 : 0]  rd_pix_data;

logic [ROW_CNT_W - 1 : 0]                     row_offset_cnt;
logic [COLUMN_CNT_W - 1 : 0]                  column_offset_cnt;

logic                                         row_valid;
logic                                         column_valid;
logic                                         data_valid;

logic [WINDOW_SIZE - 1 : 0]                   valid_reg;
logic                                         valid;
logic                                         valid_allowed;

logic [PIX_DATA_W - 1 : 0]                    wr_temp_data;
logic                                         wr_temp_valid;

typedef logic [WINDOW_SIZE - 1 : 0][WINDOW_SIZE - 1 : 0][PIX_DATA_W - 1 : 0] window_t;

window_t window_reg;

genvar ram_number;
generate
  // begin
    for( ram_number = 0; ram_number < RAM_AMOUNT; ram_number++ )
      begin : ram
        dual_port_ram #(
          .DATA_WIDTH ( PIX_DATA_W              ),
          .ADDR_WIDTH ( PIX_ADDR_W              )
        ) dual_port_ram (
          .clk_i      ( clk_i                   ),

          .wr_en_i    ( wr_pix_en               ),
          .wr_addr_i  ( wr_pix_addr             ),
          .wr_data_i  ( wr_pix_data[ram_number] ),

          .rd_en_i    ( rd_pix_en               ),
          .rd_addr_i  ( rd_pix_addr             ),
          .rd_data_o  ( rd_pix_data[ram_number] )
        );
      end
  // end
endgenerate

//*********************************
// image pixel valid determine
//*********************************

always_ff @( posedge clk_i )
  if( vd_stb )
    row_offset_cnt <= '0;
  else
    if( hd_stb )
      row_offset_cnt <= row_offset_cnt + 1'b1;

always_ff @( posedge clk_i )
  if( hd_stb )
    column_offset_cnt <= '0;
  else
    column_offset_cnt <= column_offset_cnt + 1'b1;

always_ff @( posedge clk_i )
  begin
    row_valid    <= ( row_offset_cnt    >= ROW_START_OFFSET            ) && ( row_offset_cnt    <= ( ROW_START_OFFSET + IMAGE_HEIGHT       ) );
    column_valid <= ( column_offset_cnt >= ( COLUMN_START_OFFSET - 2 ) ) && ( column_offset_cnt < ( COLUMN_START_OFFSET + IMAGE_WIDTH - 2 ) );
  end

assign data_valid = row_valid && column_valid;

//*********************************
// input reg logic
//*********************************

always_ff @( posedge clk_i )
  if( data_valid )
    wr_temp_data <= pix_data_i;

always_ff @( posedge clk_i )
  wr_temp_valid <= data_valid;

//***************************
// ram write logic 
//***************************

assign wr_pix_en = wr_temp_valid;

always_ff @( posedge clk_i )
  if( hd_stb )
    wr_pix_addr <= '0;
  else
    if( wr_pix_en )
      wr_pix_addr <= wr_pix_addr + 1'b1;

always_comb
  begin
    wr_pix_data[0] = wr_temp_data;
    for( int i = 1; i < RAM_AMOUNT; i++ )
      wr_pix_data[i] = rd_pix_data[i - 1];
  end

//***************************
// ram read logic
//***************************

assign rd_pix_en = data_valid;

always_ff @( posedge clk_i )
  if( hd_stb )
    rd_pix_addr <= '0;
  else
    if( rd_pix_en )
      rd_pix_addr <= rd_pix_addr + 1'b1;

//******************************
// slicing windows shift reg
//******************************

always_ff @( posedge clk_i )
  if( wr_pix_en )
    for( int i = 0; i < WINDOW_SIZE; i++ )
      begin
        if( i == 0 )
          window_reg[i][0] <= wr_temp_data;
        else
          window_reg[i][0] <= rd_pix_data[i - 1];
        for( int j = 1; j < WINDOW_SIZE; j++ )
          window_reg[i][j] <= window_reg[i][j - 1];
      end

assign win_data_o = window_reg;

//***************************
// valid control logic
//***************************

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    valid_reg <= '0;
  else
    begin
      valid_reg[0] <= wr_pix_en;
      for( int i = 1; i < ( WINDOW_SIZE - 1 ); i++ )
        valid_reg[i] <= valid_reg[i - 1];
    end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    valid <= 1'b0;
  else
    if( !wr_pix_en )
      valid <= 1'b0;
    else
      if( valid_reg[WINDOW_SIZE - 2] && valid_allowed )
        valid <= 1'b1;

assign valid_allowed = ( row_offset_cnt >= ( ROW_START_OFFSET + WINDOW_SIZE ) );

assign win_valid_o = valid;

endmodule : window_buffer
