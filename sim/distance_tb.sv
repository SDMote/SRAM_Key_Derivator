`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.12.2025 11:44:14
// Design Name: 
// Module Name: distance_tb
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


module distance_tb();
    
    localparam MAX_CODE_SIZE = 16;
    localparam MAX_CYCLES = 10;
    localparam CODE_INDX_SIZE = $clog2(MAX_CODE_SIZE);
    localparam COUNT_SIZE = $clog2(MAX_CYCLES);
    localparam DIST_SIZE = $clog2(MAX_CODE_SIZE*MAX_CYCLES+1);
    localparam SUM_SIZE = $clog2(MAX_CYCLES+1);
    logic [SUM_SIZE-1:0] bit_sums [MAX_CODE_SIZE-1:0];
    logic [MAX_CODE_SIZE-1:0] codeword;
    logic [CODE_INDX_SIZE-1:0] code_size;
    logic [COUNT_SIZE-1:0] cycles;
    logic [DIST_SIZE-1:0] distance;
        
    initial begin
        code_size = 4'd6;
        cycles = 4'd3;
        codeword = 16'bxxxx_xxxx_x000_0000;
        for(int i=0; i<MAX_CODE_SIZE; i++) begin
            bit_sums[i] = 4'd0;
        end
        #10
        bit_sums[0] = 4'd3;
        #10
        bit_sums[1] = 4'd2;
        #10
        bit_sums[2] = 4'd4;
        #10
        bit_sums[5] = 4'd3;
        #10
        bit_sums[6] = 4'd4;
        #10
        bit_sums[7] = 4'd1;
        #10
        bit_sums[8] = 4'd4;
        #10
        bit_sums[9] = 4'd4;
        #10
        codeword = 16'bxxxx_xxxx_x110_0101;
        #10
        codeword = 16'bxxxx_xxxx_x100_0111;
        #10
        code_size = 4'd7;
        codeword = 16'bxxxx_xxxx_0100_0111;
        #10
        codeword = 16'bxxxx_xxxx_0110_0101;
        #10
        bit_sums[1] = 4'd0;
    end 
    
    distance #(
        .MAX_CODE_SIZE(MAX_CODE_SIZE),   // maximum size of codewords in bits
        .MAX_CYCLES(MAX_CYCLES)       // maximum number of power-on cycles
        ) DUT (
        .bit_sums(bit_sums),    // WORDS*WIDTH array input: current buffer content
        .codeword(codeword),    // MAX_CODE_SIZE bits input: selected codeword value
        .code_size(code_size),   // configured codeword size in bits
        .cycles(cycles),      // configured number of power-on cycles
        .distance(distance)     // 
    );
endmodule
