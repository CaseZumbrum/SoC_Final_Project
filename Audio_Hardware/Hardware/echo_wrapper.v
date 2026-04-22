`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Case Zumbrum
//////////////////////////////////////////////////////////////////////////////////


module echo_wrapper(
    input clk,
    input rst_n,
    input [11:0] sample_in,
    output [11:0] sample_out
    );
    
   echo echo_inst (.clk(clk), .rst_n(rst_n), .sample_in(sample_in), .sample_out(sample_out));
endmodule
