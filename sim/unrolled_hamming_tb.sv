`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 13.11.2025
// Design Name: sram_puf
// Module Name: unrolled_hamming_tb
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module unrolled_hamming_tb();
    
    localparam UNROLL = 4;
    localparam MAX_CODE_SIZE = 7;
    localparam READ_SIZE = MAX_CODE_SIZE + UNROLL - 1;
    localparam INDX_SIZE = $clog2(MAX_CODE_SIZE);
    logic clk;
    logic [READ_SIZE-1:0] readout;
    logic [MAX_CODE_SIZE-1:0] code;
    logic [INDX_SIZE-1:0] size;
    logic [INDX_SIZE-1:0] d [UNROLL-1:0];
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 1'b1;
        size = 3'd5;
        code = 7'b0111010;
        readout = 10'b1011001010;
        #10
        readout = 10'b1100110010;
        #10
        readout = 10'b1011011110;
        #10
        readout = 10'b0111010111;
    end
    
    
    unrolled_hamming #(
        .MAX_CODE_SIZE(MAX_CODE_SIZE),     // maximum size of codewords in bits
        .SEQUENCE_UNROLL(UNROLL)     // number of sequences processed together
        ) DUT (
        .code_size(size),   // configured codeword size in bits
        .codeword(code),    // selected codeword value to calculate distance
        .readout(readout),     // read sequences
        .distances(d)    // calculated hamming distances
    );
endmodule
