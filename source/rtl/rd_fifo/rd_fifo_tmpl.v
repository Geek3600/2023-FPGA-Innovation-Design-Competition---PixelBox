// Created by IP Generator (Version 2022.2-SP1-Lite build 132640)
// Instantiation Template
//
// Insert the following codes into your Verilog file.
//   * Change the_instance_name to your own instance name.
//   * Change the signal names in the port associations


rd_fifo the_instance_name (
  .wr_clk(wr_clk),                    // input
  .wr_rst(wr_rst),                    // input
  .wr_en(wr_en),                      // input
  .wr_data(wr_data),                  // input [127:0]
  .wr_full(wr_full),                  // output
  .wr_water_level(wr_water_level),    // output [10:0]
  .almost_full(almost_full),          // output
  .rd_clk(rd_clk),                    // input
  .rd_rst(rd_rst),                    // input
  .rd_en(rd_en),                      // input
  .rd_data(rd_data),                  // output [31:0]
  .rd_empty(rd_empty),                // output
  .rd_water_level(rd_water_level),    // output [12:0]
  .almost_empty(almost_empty)         // output
);
