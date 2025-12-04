`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.12.2025 16:35:48
// Design Name: 
// Module Name: key_derivator_tb
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


module key_derivator_tb();
    
    localparam MAX_KEY_SIZE = 16;
    localparam MAX_BOOK_SIZE = 8;
    localparam MAX_CODE_SIZE = 8;
    localparam MAX_CYCLES = 32;
    localparam PARAM_NUMBER = MAX_BOOK_SIZE + 6;
    localparam PARAM_INDX_SIZE = $clog2(PARAM_NUMBER);
    
    logic clk, rst, start, valid;
    logic [MAX_KEY_SIZE-1:0] key;
    logic [PARAM_INDX_SIZE-1:0] index;
    logic [31:0] param;
    int i;
    string number;
    string file_name;
    
    always #5 clk = ~clk;
    
    //index:
    //0: key_size
    //1: book_size
    //2: code_size
    //3: th_low
    //4: th_high
    //5: cycles
    //else: codebook[index-6]
    
    always_ff @(posedge clk) begin
        if(rst) begin
            i = 0;
            file_name = {"L45_", $sformatf("%0d", i), ".mem"};
            $display("reading memory L45_%0d", i);
            $readmemh(file_name, DUT.Control.Buffer.sram.i_SRAM_1P_behavioral_bm_bist.memory);
        end
        else begin
            if(DUT.Control.on == 1'b0) begin
                if(i == 3)
                    i = 0;
                else
                    i = i + 1;
                file_name = {"L45_", $sformatf("%0d", i), ".mem"};
                $display("reading memory L45_%0d", i);
                $readmemh(file_name, DUT.Control.Buffer.sram.i_SRAM_1P_behavioral_bm_bist.memory);
            end
        end
    end
    
    initial begin
        clk = 1'b1;
        rst = 1'b0;
        start = 1'b0;
        index = 4'd0;
        param = 32'd0;
        #3
        rst = 1'b1;
        #10
        rst = 1'b0;
        #10
        param = 32'd8;  // key size
        #10
        index = 4'd1;
        param = 32'd4;  // book_size
        #10
        index = 4'd2;
        param = 32'd7;  // code_size
        #10
        index = 4'd3;
        param = 32'd4;  // th_low
        #10
        index = 4'd4;
        param = 32'd24;  // th_high
        #10
        index = 4'd5;
        param = 32'd4;  // cycles
        #10
        index = 4'd6;
        param = {25'd0 ,7'b0000000};  // code 0
        #10
        index = 4'd7;
        param = {25'd0 ,7'b0000111};  // code 1
        #10
        index = 4'd8;
        param = {25'd0 ,7'b1001010};  // code 2
        #10
        index = 4'd9;
        param = {25'd0 ,7'b0101011};  // code 3
        start = 1'b1; 
        #10
        start = 1'b0;            
    end
    
    key_derivator #(
        .MAX_KEY_SIZE(MAX_KEY_SIZE),  // maximum size of derived key in bits
        .MAX_BOOK_SIZE(MAX_BOOK_SIZE), // maximum number of codewords
        .MAX_CODE_SIZE(MAX_CODE_SIZE), // maximum size of codewords in bits
        .MAX_CYCLES(MAX_CYCLES)     // maximum number of power-on cycles
        ) DUT (
        .clock(clk),       // 1 bit input: clock signal
        .reset(rst),       // 1 bit input: reset signal
        .index(index),       // clog2(MAX_BOOK_SIZE+6) bits input: parameter selection index
        .param(param),       // 32 bits input: parameter value
        .start(start),       // 1 bit input: start signal
        .key(key),         // MAX_KEY_SIZE bits output: derivated key
        .valid(valid)        // 1 bit input: key valid flag
    );

endmodule
