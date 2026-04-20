`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2026 11:23:10 PM
// Design Name: 
// Module Name: echo_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module echo_wrapper(
    input clk,
    input rst_n,
    input [11:0] sample_in,
    output [11:0] sample_out
    );
    
   echo echo_inst (.clk(clk), .rst_n(rst_n), .sample_in(sample_in), .sample_out(sample_out));
endmodule
