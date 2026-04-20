`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2026 11:13:56 PM
// Design Name: 
// Module Name: echo
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


//module echo(
//    input logic clk,
//    input logic rst_n,
//    input logic[11:0] sample_in,
//    input logic[11:0] sample_out
//    );
    
//    logic[11:0] buffer [1024];
//    logic[9:0] index;
//    logic[31:0] count = 0;
    
//    assign sample_out = buffer[index];
    
//    always_ff @(posedge clk or negedge rst_n)
//    begin
//        index <= index;
    
//        if(rst_n == 0) begin
//            buffer <= '{ default : 'b0 };
//        end 
//        else begin
//            buffer[index] <= sample_in;
//            count <= count + 1;
//            if (count == 10) begin
//                index <= index + 1;
//                count <= 0;
//            end
            
//        end
//    end
    
//endmodule


module echo #(
    parameter DELAY = 48000        // ~1 second at 48kHz
)(
    input  logic clk,
    input  logic rst_n,
    input  logic signed [11:0] sample_in,
    output logic signed [11:0] sample_out
);

    logic slow_clk;
    clk_div clk_div_inst(.clk(clk), .rst_n(rst_n), .out(slow_clock));

    // Circular buffer
    logic signed [11:0] buffer [0:DELAY-1];

    logic [$clog2(DELAY)-1:0] wr_ptr;
    logic [$clog2(DELAY)-1:0] rd_ptr;

    logic signed [11:0] delayed_sample;
    logic signed [12:0] sum; // extra bit to prevent overflow

    always_ff @(posedge slow_clock) begin
        if (rst_n == 0) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            // Read delayed sample
            delayed_sample <= buffer[rd_ptr];

            // Write current sample into buffer
            buffer[wr_ptr] <= sample_in;

            // Increment pointers (circular)
            wr_ptr <= (wr_ptr == DELAY-1) ? 0 : wr_ptr + 1;
            rd_ptr <= (rd_ptr == DELAY-1) ? 0 : rd_ptr + 1;

            // Apply gain via shift (cheap hardware)
            sum = sample_in + (delayed_sample >>> 1);

            // Optional saturation (recommended)
            if (sum >  $signed({1'b0, {(11){1'b1}}}))
                sample_out <=  $signed({1'b0, {(11){1'b1}}});
            else if (sum < $signed({1'b1, {(11){1'b0}}}))
                sample_out <= $signed({1'b1, {(11){1'b0}}});
            else
                sample_out <= sum[11:0];
            end

    end

endmodule
