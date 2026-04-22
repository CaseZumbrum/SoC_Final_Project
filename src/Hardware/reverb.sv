`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Case Zumbrum
// Hardware acceleration for reverb effect
//////////////////////////////////////////////////////////////////////////////////



module reverb #(
    parameter DELAY = 4800
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
    logic signed [12:0] sum;

    always_ff @(posedge slow_clock) begin
        if (rst_n == 0) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            // Read sample
            delayed_sample <= buffer[rd_ptr];

            // Write sample to buffer
            buffer[wr_ptr] <= sample_in + (buffer[rd_ptr] >>> 3);

            wr_ptr <= (wr_ptr == DELAY-1) ? 0 : wr_ptr + 1;
            rd_ptr <= (rd_ptr == DELAY-1) ? 0 : rd_ptr + 1;

            sum = sample_in + (delayed_sample >>> 3);

            // avoid saturation
            if (sum >  $signed({1'b0, {(11){1'b1}}}))
                sample_out <=  $signed({1'b0, {(11){1'b1}}});
            else if (sum < $signed({1'b1, {(11){1'b0}}}))
                sample_out <= $signed({1'b1, {(11){1'b0}}});
            else
                sample_out <= sum[11:0];
            end

    end

endmodule
