`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 06.11.2025
// Design Name: sram_puf
// Module Name: buffer_tb
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define FUNCTIONAL

module buffer_tb();

    localparam MAX_BOOK_SIZE = 8;
    localparam MAX_CODE_SIZE = 16;
    localparam MAX_CYCLES = 32; 
    localparam SEQUENCES = 32;
    localparam SEQUENCE_UNROLL = 4;
    localparam BOOK_INDX_SIZE = $clog2(MAX_BOOK_SIZE);
    localparam CODE_INDX_SIZE = $clog2(MAX_CODE_SIZE);
    
    logic clk, rst, start, last, advance;
    logic [MAX_CODE_SIZE-1:0] codebook [MAX_BOOK_SIZE-1:0];
    logic [MAX_CODE_SIZE-1:0] codeword;
    logic [BOOK_INDX_SIZE-1:0] book_size;
    logic [CODE_INDX_SIZE-1:0] code_size;
    logic [BOOK_INDX_SIZE-1:0] code_index;
    
    
    assign codeword = codebook[code_index];
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 1'b1;
        rst = 1'b0;
        start = 1'b0;
        advance = 1'b0;
        codebook[0] = 7'b0110101;
        codebook[1] = 7'b1101010;
        codebook[2] = 7'b1010101;
        codebook[3] = 7'b0101011;
        code_size = 4'd6;
        book_size = 3'd3;
        $readmemh("init.mem", DUT.sram.i_SRAM_1P_behavioral_bm_bist.memory);
        #13
        rst = 1'b1;
        #10
        rst = 1'b0;
        #20
        start = 1'b1;
        #10
        start = 1'b0;
        #400
        start = 1'b1;
        #10
        start = 1'b0;
        advance = 1'b1;
        #400
        advance = 1'b0;
        #400
        start = 1'b1;
        #10
        start = 1'b0;        
    end
      
    
    buffer #(
        .MAX_BOOK_SIZE(MAX_BOOK_SIZE), // maximum number of codewords
        .MAX_CODE_SIZE(MAX_CODE_SIZE), // maximum size of codewords in bits
        .MAX_CYCLES(MAX_CYCLES),    // maximum number of power-on cycles
        .SEQUENCES(SEQUENCES),     // number of sequences processed together
        .SEQUENCE_UNROLL(SEQUENCE_UNROLL) // number of sequences processed together
        ) DUT (
        .clock(clk),       // 1 bit input: clock signal
        .reset(rst),       // 1 bit input: reset signal
        .book_size(book_size),   // configured number of codewords
        .code_size(code_size),   // configured codeword size in bits
        .code_index(code_index), 
        .codeword(codeword),    //
        .start(start),       //
        .last(last),
        .advance(advance)
    );
    
endmodule
