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
    localparam MAX_CODE_SIZE = 8;
    localparam MAX_CYCLES = 32; 
    localparam SEQUENCES = 8;
    localparam BOOK_INDX_SIZE = $clog2(MAX_BOOK_SIZE);
    localparam CODE_INDX_SIZE = $clog2(MAX_CODE_SIZE);
    localparam SUM_SIZE = $clog2(MAX_CODE_SIZE*MAX_CYCLES+1);
    
    logic clk, rst, start, last_cycle, last_sequence, success, selected_bit;
    logic [MAX_CODE_SIZE-1:0] codebook [MAX_BOOK_SIZE-1:0];
    logic [MAX_CODE_SIZE-1:0] codeword;
    logic [BOOK_INDX_SIZE-1:0] book_size;
    logic [CODE_INDX_SIZE-1:0] code_size;
    logic [BOOK_INDX_SIZE-1:0] code_index;
    logic [SUM_SIZE-1:0] th_low, th_high;
    
    
    assign codeword = codebook[code_index];
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 1'b1;
        rst = 1'b0;
        start = 1'b0;
        last_cycle = 1'b0;
        th_low = 9'd4;
        th_high = 9'd24;
        codebook[0] = 7'b0000000;
        codebook[1] = 7'b0000111;
        codebook[2] = 7'b0101011;
        codebook[3] = 7'b1001010;
        code_size = 4'd6;
        book_size = 3'd3;
        $readmemh("L45_0.mem", DUT.Memory.i_SRAM_1P_behavioral_bm_bist.memory);
        #13
        rst = 1'b1;
        #10
        rst = 1'b0;
        repeat(10) begin
            repeat(3) begin
                #20
                start = 1'b1;
                #10
                start = 1'b0;
                while(last_sequence==1'b0) #10;
            end
            #20
            last_cycle = 1'b1;
            #10
            start = 1'b1;
            #10
            start = 1'b0;      
            while(last_sequence==1'b0) #10;
            #10
            last_cycle = 1'b0;
        end
    end
      
    
    buffer #(
        .MAX_BOOK_SIZE(MAX_BOOK_SIZE), // maximum number of codewords
        .MAX_CODE_SIZE(MAX_CODE_SIZE), // maximum size of codewords in bits
        .MAX_CYCLES(MAX_CYCLES),    // maximum number of power-on cycles
        .SEQUENCES(SEQUENCES)      // number of sequences processed together
        ) DUT (
        .clock(clk),       // 1 bit input: clock signal
        .reset(rst),       // 1 bit input: reset signal
        .book_size(book_size),   // configured number of codewords
        .code_size(code_size),   // configured codeword size in bits
        .code_index(code_index), 
        .th_low(th_low),   // 
        .th_high(th_high),   // 
        .codeword(codeword),    //
        .start(start),       //
        .last_cycle(last_cycle),
        .last_sequence(last_sequence),
        .success(success),
        .selected_bit(selected_bit) 
    );
    
endmodule
