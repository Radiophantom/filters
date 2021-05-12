module lut_divider #(
  parameter int DIVIDEND_W  = 16,
  parameter int QUOTIENT_W  = 12,
  parameter int DIVISOR     = 9
)(
  input                         rst_i,
  input                         clk_i,

  input                         valid_i,
  input   [DIVIDEND_W - 1 : 0]  dividend_i,

  output                        valid_o,
  output  [QUOTIENT_W - 1 : 0]  quotient_o
);

logic [35 : 0] quotient;

logic [17 : 0] dividend;
logic [17 : 0] divisor;

logic [1 : 0]  valid_tmp;

// 13 numbers after dot precision
initial
  begin
    if( DIVISOR == 9 )
      divisor = 18'b0001110001111;
    else
      if( DIVISOR == 25 )
        divisor = 18'b0000101001000;
      else
        if( DIVISOR == 49 )
          divisor = 18'b0000010101000;
  end

always @( posedge clk_i, posedge rst_i )
  if( rst_i )
    valid_tmp <= 2'b00;
  else
    valid_tmp <= { valid_tmp[0], valid_i };

always_ff @( posedge clk_i )
  begin
    dividend <= 18'( dividend_i );
    quotient <= dividend * divisor;
  end

assign valid_o    = valid_tmp[1];
assign quotient_o = quotient[13 +: QUOTIENT_W];

endmodule : lut_divider
