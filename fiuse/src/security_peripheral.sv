`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 05.11.2025
// Design Name: sram_puf
// Module Name: security_peripheral
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


///////////////////////////// Instantiation Template /////////////////////////////
//    security_peripheral #(
//        .KEY_SIZE(64),  // size of derived key in bits
//        .THRESHOLD(1),  // 
//        .CYCLES(32),    // number of power-on cycles
//        .WORDS(4),      // 
//        ) instance_name (
//        .clock(),       // 1 bit input: clock signal
//        .reset()        // 1 bit input: reset signal
//    );
//////////////////////////////////////////////////////////////////////////////////

module security_peripheral #(
    KEY_SIZE = 64,  // size of generated key in bits
    THRESHOLD = 1,
    CYCLES = 32,     // number of power-on cycles
    WORDS = 4
    )(
    clock,
    reset
    );
    
    input  logic clock;
    input  logic reset;
    
    localparam BOOK_SIZE = 4;       // number of codewords
    localparam CODE_SIZE = 7;      // size of codewords in bits
    logic [CODE_SIZE-1:0] codebook [BOOK_SIZE-1:0];
    
    always_comb begin
        codebook[0] = 7'b0000000;
        codebook[1] = 7'b0000111;
        codebook[2] = 7'b0101011;
        codebook[3] = 7'b1001010;
    end
    
    localparam MEMORY_WIDTH = 16;   // memory word size in bits
    localparam MEMORY_DEPTH = 1024; // memory number of words
    localparam BOOK_INDX_SIZE = $clog2(BOOK_SIZE);
    logic [KEY_SIZE-1:0] key, new_key;
    logic start;
    logic done;
    
    enum logic [0:0] {RUN, IDLE} state;
    
    always_ff @(posedge clock) begin
        if (reset) begin
            state <= RUN;
            start <= 0;
            key <= {KEY_SIZE{1'bx}};
        end
        else begin
            case(state)
                RUN: begin
                    start <= 1'b1;
                    if(done) begin
                        state <= IDLE;
                        key <= new_key;
                    end
                end
                IDLE: begin
                    state <= IDLE;
                    start <= 1'b0;
                end
            endcase
        end
    end
    
    logic [CODE_SIZE-1:0] codeword;
    logic [BOOK_INDX_SIZE-1:0] code_index;
    assign codeword = codebook[code_index];
    
    secret_generator #(
        .KEY_SIZE(KEY_SIZE),  // size of derived key in bits
        .BOOK_SIZE(BOOK_SIZE), // number of codewords
        .CODE_SIZE(CODE_SIZE), // size of codewords in bits
        .THRESHOLD(THRESHOLD),  // 
        .CYCLES(CYCLES),    // number of power-on cycles
        .WORDS(WORDS)           // number of words read on each powe-on cycle
        ) Extractor (
        .clock(clock),
        .reset(reset),
        .start(start),       //
        .code_index(code_index),  // clog2(MAX_BOOK_SIZE) bits output: codeword selection index
        .codeword(codeword),    // MAX_CODE_SIZE bits input: selected codeword value
        .key(new_key),         // MAX_KEY_SIZE bits output: derivated key
        .done(done)         // 1 bit output: key is valid
    );


///////////////////////////////// User Functions /////////////////////////////////
    
    
//////////////////////////////////////////////////////////////////////////////////
    
endmodule
