`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 05.11.2025
// Design Name: sram_puf
// Module Name: key_derivator
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


///////////////////////////// Instantiation Template /////////////////////////////
//    key_derivator #(
//        .MAX_KEY_SIZE(64),  // maximum size of derived key in bits
//        .MAX_BOOK_SIZE(32), // maximum number of codewords
//        .MAX_CODE_SIZE(15), // maximum size of codewords in bits
//        .MAX_CYCLES(32),    // maximum number of power-on cycles
//        .WORDS(4)           // number of words read on each powe-on cycle
//        ) instance_name (
//        .clock(),       // 1 bit input: clock signal
//        .reset(),       // 1 bit input: reset signal
//        .index(),       // clog2(MAX_BOOK_SIZE+6) bits input: parameter selection index
//        .param(),       // 32 bits input: parameter value
//        .start(),       // 1 bit input: start signal
//        .key(),         // MAX_KEY_SIZE bits output: derivated key
//        .valid()        // 1 bit input: key valid flag
//    );
//////////////////////////////////////////////////////////////////////////////////

module key_derivator #(
    MAX_KEY_SIZE = 64,  // maximum size of generated key in bits
    MAX_BOOK_SIZE = 32, // maximum number of codewords
    MAX_CODE_SIZE = 15, // maximum size of codewords in bits
    MAX_CYCLES = 32,     // maximum number of power-on cycles
    WORDS = 4
    )(
    clock,
    reset,
    index,
    param,
    start,
    key,
    valid
    );
    
    // Parameters
    localparam MEMORY_WIDTH = 16;   // memory word size in bits
    localparam MEMORY_DEPTH = 1024; // memory number of words
    
    localparam PARAM_NUMBER = MAX_BOOK_SIZE + 6;
    localparam PARAM_INDX_SIZE = $clog2(PARAM_NUMBER);
    
    // Ports
    input  logic clock;
    input  logic reset;
    input  logic [PARAM_INDX_SIZE-1:0] index;
    input  logic [31:0] param;
    input  logic start;
    output logic [MAX_KEY_SIZE-1:0] key;
    output logic valid;
    
    
    localparam ADDRESS_SIZE = $clog2(MEMORY_DEPTH);
    localparam KEY_INDX_SIZE = $clog2(MAX_KEY_SIZE);
    localparam BOOK_INDX_SIZE = $clog2(MAX_BOOK_SIZE);
    localparam CODE_INDX_SIZE = $clog2(MAX_CODE_SIZE);
    localparam COUNT_SIZE = $clog2(MAX_CYCLES);
    localparam DIST_SIZE = $clog2(MAX_CODE_SIZE*MAX_CYCLES+1);
    // configurable parameter values 
    logic [KEY_INDX_SIZE-1:0] key_size;
    logic [BOOK_INDX_SIZE-1:0] book_size;
    logic [CODE_INDX_SIZE-1:0] code_size;
    logic [DIST_SIZE-1:0] th_low;
    logic [DIST_SIZE-1:0] th_high;
    logic [COUNT_SIZE-1:0] cycles;
    logic [MAX_CODE_SIZE-1:0] codebook [MAX_BOOK_SIZE-1:0];
    logic [MAX_KEY_SIZE-1:0] new_key;
    logic start_reg;
    logic done;
    
    enum logic [0:0] {CONF, RUN} state;
    
    always_ff @(posedge clock) begin
        if (reset) begin
            state <= CONF;
            start_reg <= 0;
            key_size <= 15; // 16 bits
            book_size <= 7; // 8 codes
            code_size <= 6; // 7 bits
            cycles <= 3;    // 4 cycles
            th_low <= 4;
            th_high <= 24;
            for(int i=0; i<MAX_BOOK_SIZE; i++) begin
                codebook[i] <= 0;
            end
            key <= {MAX_KEY_SIZE{1'bx}};
        end
        else begin
            start_reg <= start;
            case(state)
                CONF: begin
                    case(index)
                        'd0: key_size <= param-1;
                        'd1: book_size <= param-1;
                        'd2: code_size <= param-1;
                        'd3: th_low <= param;
                        'd4: th_high <= param;
                        'd5: cycles <= param-1;
                        default: codebook[index-6] <= param;
                    endcase
                    if((start==1'b1) && (start_reg==1'b0)) begin
                        state <= RUN;
                        valid <= 1'b0;
                    end
                end
                RUN: begin
                    if(done) begin
                        state <= CONF;
                        key <= new_key;
                        valid <= 1'b1;
                    end
                end
            endcase
        end
    end
    
    logic [MAX_CODE_SIZE-1:0] codeword;
    logic [BOOK_INDX_SIZE-1:0] code_index;
    assign codeword = codebook[code_index];
    
    tmvs #(
        .MAX_KEY_SIZE(MAX_KEY_SIZE),  // maximum size of derived key in bits
        .MAX_BOOK_SIZE(MAX_BOOK_SIZE), // maximum number of codewords
        .MAX_CODE_SIZE(MAX_CODE_SIZE), // maximum size of codewords in bits
        .MAX_CYCLES(MAX_CYCLES),    // maximum number of power-on cycles
        .WORDS(WORDS)           // number of words read on each powe-on cycle
        ) Control (
        .clock(clock),
        .reset(reset),
        .start(start),       //
        .key_size(key_size),    // configured key size in bits
        .book_size(book_size),   // configured number of codewords
        .code_size(code_size),   // configured codeword size in bits
        .th_low(th_low),
        .th_high(th_high),
        .cycles(cycles),      // configured number of power-on cycles
        .code_index(code_index),  // clog2(MAX_BOOK_SIZE) bits output: codeword selection index
        .codeword(codeword),    // MAX_CODE_SIZE bits input: selected codeword value
        .key(new_key),         // MAX_KEY_SIZE bits output: derivated key
        .done(done)         // 1 bit output: key is valid
    );

    
endmodule
