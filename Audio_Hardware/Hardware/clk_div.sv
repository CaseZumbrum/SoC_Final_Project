`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2026 10:41:55 PM
// Design Name: 
// Module Name: clk_div
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


module clk_div #(
    parameter CLK_FREQ   = 100_000_000,
    parameter SAMPLE_RATE = 48_000
)(
    input  logic clk,
    input  logic rst_n,
    output logic out   // 1-cycle pulse at 48kHz
);

    // מספיק bits to hold accumulator
    localparam ACC_WIDTH = 32;

    logic [ACC_WIDTH-1:0] acc;

    always_ff @(posedge clk) begin
        if (rst_n == 0) begin
            acc       <= 0;
            out <= 0;
        end else begin
            acc <= acc + SAMPLE_RATE;

            if (acc >= CLK_FREQ) begin
                acc       <= acc - CLK_FREQ;
                out <= 1;
            end else begin
                out <= 0;
            end
        end
    end

endmodule
