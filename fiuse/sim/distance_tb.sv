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
    
    localparam CODE_SIZE = 7;
    localparam CYCLES = 4;
    localparam CODE_INDX_SIZE = $clog2(CODE_SIZE);
    localparam COUNT_SIZE = $clog2(CYCLES);
    localparam DIST_SIZE = $clog2(CODE_SIZE*CYCLES+1);
    localparam SUM_SIZE = $clog2(CYCLES+1);
    logic [SUM_SIZE-1:0] bit_sums [CODE_SIZE-1:0];
    logic [CODE_SIZE-1:0] codeword;
    logic [DIST_SIZE-1:0] distance;
        
    initial begin
        codeword = 16'bxxxx_xxxx_x000_0000;
        for(int i=0; i<CODE_SIZE; i++) begin
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
    end 
    
    distance #(
        .CODE_SIZE(CODE_SIZE),   // maximum size of codewords in bits
        .CYCLES(CYCLES)       // maximum number of power-on cycles
        ) DUT (
        .bit_sums(bit_sums),    // WORDS*WIDTH array input: current buffer content
        .codeword(codeword),    // MAX_CODE_SIZE bits input: selected codeword value
        .distance(distance)     // 
    );
endmodule
