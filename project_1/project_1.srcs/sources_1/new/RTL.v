`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/05/2024 05:52:26 PM
// Design Name: 
// Module Name: RTL
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
module axi_stream_insert_header #(
    parameter DATA_WD = 32,
    parameter DATA_BYTE_WD = DATA_WD / 8,
    parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
) (
    input clk,
    input rst_n,
    
    input valid_in,
    input [DATA_WD-1:0] data_in,
    input [DATA_BYTE_WD-1:0] keep_in,
    input last_in,  
    output reg ready_in,
   
    output reg valid_out,
    output reg [DATA_WD-1:0] data_out,
    output reg [DATA_BYTE_WD-1:0] keep_out,
    output reg last_out,
    input ready_out,
    
    input valid_insert,
    input [DATA_WD-1:0] data_insert,
    input [DATA_BYTE_WD-1:0] keep_insert,
    input [BYTE_CNT_WD-1 : 0] byte_insert_cnt,
    output reg ready_insert      
);

reg [DATA_WD-1:0] buffer_data;
reg [DATA_BYTE_WD-1:0] buffer_keep;
reg [2*DATA_WD-1:0] buffer_in;
reg [2*DATA_BYTE_WD-1:0] buffer_in_keep;
reg buffer_valid = 0, buffer_in_valid = 0;
reg header_processed = 0;
integer i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        {buffer_data, buffer_keep, buffer_in, buffer_in_keep, valid_out, buffer_valid, buffer_in_valid, header_processed, ready_in, ready_insert} <= 0;
    end else if (ready_out) begin
        if (valid_insert && !header_processed) begin
            for (i = 0; i < DATA_BYTE_WD; i = i + 1) begin
                if (i < byte_insert_cnt) begin
                    buffer_data[i*8 +: 8] <= data_insert[i*8 +: 8];
                    buffer_keep[i] <= 1'b1;
                end else begin
                    buffer_data[i*8 +: 8] <= buffer_in[i*8 +: 8];
                    buffer_keep[i] <= buffer_in_keep[i - byte_insert_cnt];
                end
            end
            
            buffer_valid <= 1;
            header_processed <= 1;
        end 

        if (valid_in && !header_processed) begin
            buffer_in <= data_in;
            buffer_in_keep <= keep_in;
            buffer_in_valid <= 1;
        end

        if (buffer_valid) begin
            data_out <= buffer_data;
            keep_out <= buffer_keep;
            valid_out <= 1;
            last_out <= 0;
            buffer_valid <= 0;
        end else if (buffer_in_valid && header_processed) begin
            data_out <= buffer_in;
            keep_out <= buffer_in_keep;
            valid_out <= 1;
            last_out <= last_in;
            buffer_in_valid <= 0;
        end

        ready_in <= !last_in;
        ready_insert <= !header_processed;
    end
end

endmodule

