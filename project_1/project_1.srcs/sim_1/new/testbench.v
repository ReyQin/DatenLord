`timescale 1ns / 1ps

module axi_stream_insert_header_tb;

parameter DATA_WD = 32;
parameter DATA_BYTE_WD = DATA_WD / 8;
parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD);

// Inputs
reg clk;
reg rst_n;
reg valid_in;
reg [DATA_WD-1:0] data_in;
reg [DATA_BYTE_WD-1:0] keep_in;
reg last_in;
reg ready_out;
reg valid_insert;
reg [DATA_WD-1:0] data_insert;
reg [DATA_BYTE_WD-1:0] keep_insert;
reg [BYTE_CNT_WD-1:0] byte_insert_cnt;

// Outputs
wire ready_in;
wire valid_out;
wire [DATA_WD-1:0] data_out;
wire [DATA_BYTE_WD-1:0] keep_out;
wire last_out;
wire ready_insert;

// Instantiate the Unit Under Test (UUT)
axi_stream_insert_header #(
    .DATA_WD(DATA_WD),
    .DATA_BYTE_WD(DATA_BYTE_WD),
    .BYTE_CNT_WD(BYTE_CNT_WD)
) uut (
    .clk(clk), 
    .rst_n(rst_n), 
    .valid_in(valid_in), 
    .data_in(data_in), 
    .keep_in(keep_in), 
    .last_in(last_in), 
    .ready_in(ready_in), 
    .valid_out(valid_out), 
    .data_out(data_out), 
    .keep_out(keep_out), 
    .last_out(last_out), 
    .ready_out(ready_out), 
    .valid_insert(valid_insert), 
    .data_insert(data_insert), 
    .keep_insert(keep_insert), 
    .byte_insert_cnt(byte_insert_cnt), 
    .ready_insert(ready_insert)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

task send_data;
    input [DATA_WD-1:0] data;
    input [DATA_BYTE_WD-1:0] keep;
    input is_last;
    begin
        @ (posedge clk);
        valid_in = 1;
        data_in = data;
        keep_in = keep;
        last_in = is_last;
        @ (posedge clk);
        valid_in = 0;
        last_in = 0;
    end
endtask

task send_header;
    input [DATA_WD-1:0] header;
    input [DATA_BYTE_WD-1:0] keep;
    input [BYTE_CNT_WD-1:0] byte_count;
    begin
        @ (posedge clk);
        valid_insert = 1;
        data_insert = header;
        keep_insert = keep;
        byte_insert_cnt = byte_count;
        @ (posedge clk);
        valid_insert = 0;
    end
endtask

initial begin
    // Initialize Inputs
    rst_n = 0;
    valid_in = 0;
    data_in = 0;
    keep_in = 0;
    last_in = 0;
    ready_out = 1;  // Assume the downstream module is always ready
    valid_insert = 0;
    data_insert = 0;
    keep_insert = 0;
    byte_insert_cnt = 0;


    #10;
    rst_n = 1;
    #10;

    send_header(32'hdeadbeef, 4'b1111, 4);
    send_data(32'hcafebabe, 4'b1111, 1);
    #10;
   
    send_header(32'hfaceb00c, 4'b1100, 2);
    #10;

    send_data(32'h12345678, 4'b1111, 1);
    #10;

    repeat (5) begin
        send_data($random, 4'b1111, 0);
    end
    send_data($random, 4'b1111, 1); 
    
    #10;
    
    // Backpressure
    repeat (3) begin
        send_data($random, 4'b1111, 0);
        ready_out <= 0; // Apply backpressure
        #20 ready_out <= 1; // Release backpressure
    end
    send_data($random, 4'b1111, 1); // Last packet

   #10;

    $finish;
end


endmodule

