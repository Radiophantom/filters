module pipeline_adder #(
  parameter int NUMBERS_AMOUNT = 10,
  parameter int NUMBER_WIDTH   = 10,
  parameter int SUM_WIDTH      = NUMBER_WIDTH + $clog2( NUMBERS_AMOUNT )
)(
  input                                                 rst_i,
  input                                                 clk_i,

  input                                                 data_valid_i,
  input  [NUMBERS_AMOUNT - 1 : 0][NUMBER_WIDTH - 1 : 0] data_i,
  
  output                                                data_valid_o,
  output [SUM_WIDTH - 1 : 0]                            data_o
);

localparam int INPUTS_AMOUNT = NUMBERS_AMOUNT + 1;
localparam int STAGES_AMOUNT = $clog2( INPUTS_AMOUNT ) + 1;

logic [STAGES_AMOUNT - 1 : 0][INPUTS_AMOUNT - 1 : 0][SUM_WIDTH - 1 : 0] add_stages;

logic [STAGES_AMOUNT - 1 : 0]                                           valid_d;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    valid_d <= STAGES_AMOUNT'( 0 );
  else
	 begin
	   valid_d[0] <= data_valid_i;
	   for( int i = 1; i < STAGES_AMOUNT; i++ )
		  valid_d[i] <= valid_d[i - 1];
	 end

always_ff @( posedge clk_i )
  for( int i = 0; i < STAGES_AMOUNT; i++ )
    if( i == 0 )
      begin
        for( int k = 0; k < NUMBERS_AMOUNT; k++ )
          add_stages[i][k]               <= data_i[k];
        add_stages[i][INPUTS_AMOUNT - 1] <= SUM_WIDTH'( 0 );
      end
    else
      for( int j = 0; j < ( INPUTS_AMOUNT / ( i + 1 ) ); j++ )
        add_stages[i][j] <= add_stages[i - 1][j * 2] + add_stages[i - 1][j * 2 + 1];

assign data_valid_o = valid_d[STAGES_AMOUNT - 1];
assign data_o       = add_stages[STAGES_AMOUNT - 1][0];

endmodule
