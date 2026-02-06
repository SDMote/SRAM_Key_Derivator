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

    localparam WIDTH = 16;      // memory word size in bits
    localparam DEPTH = 1024;    // memory number of words
    localparam BOOK_SIZE = 4;
    localparam CODE_SIZE = 7;
    localparam THRESHOLD = 1;
    localparam CYCLES = 4; 
    localparam SEQUENCES = 8;
    localparam ADDRESS_SIZE = $clog2(DEPTH);
    localparam BOOK_INDX_SIZE = $clog2(BOOK_SIZE);
    localparam CODE_INDX_SIZE = $clog2(CODE_SIZE);
    localparam SUM_SIZE = $clog2(CODE_SIZE*CYCLES+1);
    
    logic clk, rst, start, last_cycle, last_sequence, success, selected_bit;
    logic [ADDRESS_SIZE-1:0] address;   // memory address
    logic [WIDTH-1:0] read_data;             // memory read data
    logic [CODE_SIZE-1:0] codebook [BOOK_SIZE-1:0];
    logic [CODE_SIZE-1:0] codeword;
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
        codebook[0] = 7'b0000000;
        codebook[1] = 7'b0000111;
        codebook[2] = 7'b0101011;
        codebook[3] = 7'b1001010;
        $readmemh("L45_0.mem", Memory.i_SRAM_1P_behavioral_bm_bist.memory);
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
        .WIDTH(WIDTH),     // memory word size in bits
        .DEPTH(DEPTH),   // memory number of words
        .BOOK_SIZE(BOOK_SIZE), // maximum number of codewords
        .CODE_SIZE(CODE_SIZE), // maximum size of codewords in bits
        .THRESHOLD(THRESHOLD),      // 
        .CYCLES(CYCLES),    // maximum number of power-on cycles
        .SEQUENCES(SEQUENCES)      // number of sequences processed together
        ) DUT (
        .clock(clk),       // 1 bit input: clock signal
        .reset(rst),       // 1 bit input: reset signal
        .address(address),     // 
        .read_data(read_data),   // 
        .code_index(code_index), 
        .codeword(codeword),    //
        .start(start),       //
        .last_cycle(last_cycle),
        .last_sequence(last_sequence),
        .success(success),
        .selected_bit(selected_bit) 
    );
    
    RM_IHPSG13_1P_1024x16_c2_bm_bist Memory (
        .A_ADDR(address),
        .A_CLK(clk),
        .A_DIN('d0),
        .A_DOUT(read_data),
        .A_MEN(1'b1),
        .A_WEN(1'b0),
        .A_REN(1'b1),
        .A_BM(16'b1),
        .A_BIST_EN(1'b0),
        .A_DLY(1'b0),
        .A_BIST_CLK(1'b0),
        .A_BIST_MEN(1'b0),
        .A_BIST_WEN(1'b0),
        .A_BIST_REN(1'b0),
        .A_BIST_ADDR(10'b0),
        .A_BIST_DIN(16'b0), 
        .A_BIST_BM(16'b0)
    );
    
endmodule
