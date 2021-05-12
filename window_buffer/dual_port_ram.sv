module dual_port_ram #(
  parameter int DATA_WIDTH = 8,
  parameter int ADDR_WIDTH = 5
)(
  input                       clk_i,

  input                       wr_en_i,
  input [ADDR_WIDTH - 1 : 0]  wr_addr_i,
  input [DATA_WIDTH - 1 : 0]  wr_data_i,

  input                       rd_en_i,
  input  [ADDR_WIDTH - 1 : 0] rd_addr_i,
  output [DATA_WIDTH - 1 : 0] rd_data_o
);

logic [DATA_WIDTH - 1 : 0] ram [2 ** ADDR_WIDTH - 1 : 0];
logic [DATA_WIDTH - 1 : 0] rd_data;

always_ff @( posedge clk_i )
  if( wr_en_i )
    ram[wr_addr_i] <= wr_data_i;

always_ff @( posedge clk_i )
  if( rd_en_i )
    rd_data <= ram[rd_addr_i];

assign rd_data_o = rd_data;

endmodule
