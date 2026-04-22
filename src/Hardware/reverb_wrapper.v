`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Case Zumbrum
//////////////////////////////////////////////////////////////////////////////////


module reverb_wrapper(
    input clk,
    input rst_n,
    input [11:0] sample_in,
    output [11:0] sample_out
    );
    
   reverb reverb_inst (.clk(clk), .rst_n(rst_n), .sample_in(sample_in), .sample_out(sample_out));
endmodule
