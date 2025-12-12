`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 09.12.2025
// Design Name: sram_puf
// Module Name: tmvs
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


///////////////////////////// Instantiation Template /////////////////////////////
//    tmvs #(
//        .MAX_KEY_SIZE(64),  // maximum size of derived key in bits
//        .MAX_BOOK_SIZE(32), // maximum number of codewords
//        .MAX_CODE_SIZE(15), // maximum size of codewords in bits
//        .MAX_CYCLES(32)     // maximum number of power-on cycles
//        ) instance_name (
//        .clock(),
//        .reset(),
//        .start(),       //
//        .key_size(),    // configured key size in bits
//        .book_size(),   // configured number of codewords
//        .code_size(),   // configured codeword size in bits
//        .th_low(),   // 
//        .th_high(),   // 
//        .cycles(),      // configured number of power-on cycles
//        .code_index(),  // clog2(MAX_BOOK_SIZE) bits output: codeword selection index
//        .codeword(),    // MAX_CODE_SIZE bits input: selected codeword value
//        .key(),         // MAX_KEY_SIZE bits output: derivated key
//        .done()         // 1 bit input: key is valid
//    );
//////////////////////////////////////////////////////////////////////////////////
    
module tmvs #(
    MAX_KEY_SIZE = 64,  // maximum size of generated key in bits
    MAX_BOOK_SIZE = 32, // maximum number of codewords
    MAX_CODE_SIZE = 15, // maximum size of codewords in bits
    MAX_CYCLES = 32     // maximum number of power-on cycles
    )(
    clock,
    reset,
    start,      //
    key_size,   // configured key size in bits
    book_size,  // configured number of codewords
    code_size,  // configured codeword size in bits
    th_low,
    th_high,
    cycles,     // configured number of power-on cycles
    code_index, // codeword selection index
    codeword,   // selected codeword value
    key,        // derivated key
    done        // key is valid
    );
    
    localparam KEY_INDX_SIZE = $clog2(MAX_KEY_SIZE);
    localparam BOOK_INDX_SIZE = $clog2(MAX_BOOK_SIZE);
    localparam CODE_INDX_SIZE = $clog2(MAX_CODE_SIZE);
    localparam COUNT_SIZE = $clog2(MAX_CYCLES);
    localparam DIST_SIZE = $clog2(MAX_CODE_SIZE*MAX_CYCLES+1);
    input  logic clock;
    input  logic reset;
    input  logic start;
    input  logic [KEY_INDX_SIZE-1:0] key_size;
    input  logic [BOOK_INDX_SIZE-1:0] book_size;
    input  logic [CODE_INDX_SIZE-1:0] code_size;
    input  logic [DIST_SIZE-1:0] th_low;
    input  logic [DIST_SIZE-1:0] th_high;
    input  logic [COUNT_SIZE-1:0] cycles;
    output logic [BOOK_INDX_SIZE-1:0] code_index;
    input  logic [MAX_CODE_SIZE-1:0] codeword;
    output logic [MAX_KEY_SIZE-1:0] key;
    output logic done;
    
    // TODO: this module should provide sequences and advance 1 bit and provide signals to load a new word into the shift register 
    
    localparam WIDTH = 16;
    localparam DEPTH = 1024;
    localparam OVERLAP = (MAX_CODE_SIZE-1)/WIDTH + 1;
    localparam WORDS = 4;   // at least OVERLAP + 1
    localparam ADDRESS_SIZE = $clog2(DEPTH);
    localparam SUM_SIZE = $clog2(MAX_CYCLES+1);
    localparam WORD_IDX_SIZE = $clog2(WORDS);
    localparam REG_SIZE = WORDS * WIDTH;
    localparam REG_IDX_SIZE = $clog2(REG_SIZE);
    localparam BIT_IDX_SIZE = $clog2(WIDTH);
    enum logic [1:0] {IDLE, RUN, OFF, DONE} state, state_next;
    logic [SUM_SIZE-1:0] sums [REG_SIZE-1:0];
    logic [REG_IDX_SIZE-1:0] index, index_next;
    logic [WORD_IDX_SIZE-1:0] word_index;
    logic [ADDRESS_SIZE-1:0] address, checkpoint, checkpoint_next;
    logic [WIDTH-1:0] read_data;
    logic [COUNT_SIZE-1:0] counter, counter_next;
    logic [BOOK_INDX_SIZE-1:0] code_index_next;
    logic [SUM_SIZE-1:0] sequence_sums [MAX_CODE_SIZE-1:0];
    logic [DIST_SIZE-1:0] distance;
    logic [KEY_INDX_SIZE-1:0] bit_count, bit_count_next;
    logic enable, load, full, last_cycle, shift;
    logic [MAX_KEY_SIZE-1:0] key_next;
    logic valid, success;
    logic on, ready;
    assign last_cycle = counter==cycles;
    
    always_ff @(posedge clock) begin
        if (reset) begin
            state <= IDLE;
            checkpoint <= 0;
            counter <= 0;
            index <= 0;
            code_index <= 0;
            bit_count <= 0;
            key <= {MAX_KEY_SIZE{1'bx}};
        end
        else begin
            state <= state_next;
            checkpoint <= checkpoint_next;
            counter <= counter_next;
            index <= index_next;
            code_index <= code_index_next;
            bit_count <= bit_count_next;
            key <= key_next;
        end
    end
    
    always_comb begin
        state_next = state;
        checkpoint_next = checkpoint;
        counter_next = counter;
        index_next = index;
        code_index_next = code_index;
        bit_count_next = bit_count;
        key_next = key;
        load = 1'b0;
        shift = 1'b0;
        on = 1'b1;
        valid = 1'b0;
        success = 1'b0;
        done = 1'b0;
        enable = 1'b1;
        case(state)
            IDLE: begin 
                if(start) begin
                    state_next = RUN;
                end
            end
            RUN: begin
                if(last_cycle) begin
                    if(word_index < WORDS-1)
                        load = 1'b1;
                    if(index + code_size < ((word_index+1)<<BIT_IDX_SIZE)) begin
                        valid = 1'b1;
                        if(code_index == book_size) begin
                            code_index_next = 0;
                            if(index + code_size >= REG_SIZE-1) begin
                                counter_next = 0;
                                index_next = index + 1 - ((WORDS-OVERLAP)<<BIT_IDX_SIZE);;
                                checkpoint_next = address;
                                shift = 1'b1;
                                load = 1'b1;
                            end
                            else begin
                                index_next = index + 1;
                            end 
                        end
                        else begin
                            code_index_next = code_index + 1;
                        end
                        if(distance<=th_low || distance>=th_high) begin // selection success
                            success = 1'b1;
                            key_next[bit_count] = (distance<=th_low) ? 1'b1 : 1'b0;
                            if (bit_count==key_size) begin
                                state_next = DONE;
                                counter_next = 0;
                                checkpoint_next = 0;
                                index_next = 0;
                                code_index_next = 0;
                            end
                            else begin
                                bit_count_next = bit_count + 1;
                                // discard overlapped sequences
                                code_index_next = 0;
                                if(index + (code_size<<1) >= REG_SIZE-2) begin
                                    counter_next = 0;
                                    index_next = index + code_size + 1 - ((WORDS-OVERLAP)<<BIT_IDX_SIZE);
                                    checkpoint_next = address;
                                    shift = 1'b1;
                                    load = 1'b1;
                                end
                                else begin
                                    index_next = index + code_size + 1;
                                end 
                            end
                        end
                    end
                end
                else begin
                    load = 1'b1;
                    if(full) begin
                        state_next = OFF; 
                        on = 1'b0;
                        counter_next = counter + 1;
                    end
                end
            end
            OFF: begin
                if(ready) begin
                    load = 1'b1;
                    state_next = RUN;
                end
                else begin
                    on = 1'b0;
                end
            end
            DONE: begin
                enable = 1'b0;
                done = 1'b1;
                if(start==1'b0) begin
                    state_next = IDLE;
                    bit_count_next = 0;
                    key_next = {MAX_KEY_SIZE{1'bx}};
                end
            end
            default:
                state_next = IDLE;
        endcase
        for(int i=0; i<MAX_CODE_SIZE; i++) begin
            sequence_sums[i] = sums[index+i];
        end
    end
    
    
    distance #(
        .MAX_CODE_SIZE(MAX_CODE_SIZE),   // maximum size of codewords in bits
        .MAX_CYCLES(MAX_CYCLES)       // maximum number of power-on cycles
        ) Hamming (
        .bit_sums(sequence_sums),    // WORDS*WIDTH array input: current buffer content
        .codeword(codeword),    // MAX_CODE_SIZE bits input: selected codeword value
        .code_size(code_size),   // configured codeword size in bits
        .cycles(cycles),      // configured number of power-on cycles
        .distance(distance)     // 
    );
    
    cumulator #(
        .MAX_CYCLES(MAX_CYCLES),// 
        .WIDTH(WIDTH),     // memory word size in bits
        .DEPTH(DEPTH),   // memory number of words
        .WORDS(WORDS),      // number of words in the shift register
        .OVERLAP(OVERLAP)     // number of words to keep from the back of the register when shifting
        ) Buffer (
        .clock(clock),       // 1 bit input: clock signal
        .reset(reset),       // 1 bit input: reset signal
        .enable(enable),      // 1 bit input: reset signal
        .address(address),     // clog2(WIDTH) bits output: memory address
        .data(read_data),        // WIDTH bits input: memory data
        .sums(sums),   // WORDS*WIDTH bits output: current shift register content
        .word_index(word_index),
        .checkpoint(checkpoint),  // WIDTH bits input: address checkpoint to start loading from
        .load(load),       // 1 bit input: load a new word into the dhift register
        .shift(shift),     // 1 bit input: clear registers, update checkpoint and continue
        .full(full)         // 1 bit output: shift register is full
    );   

    RM_IHPSG13_1P_1024x16_c2_bm_bist Memory (
        .A_ADDR(address),
        .A_CLK(clock),
        .A_DIN('d0),
        .A_DOUT(read_data),
        .A_MEN(on),
        .A_WEN(1'b0),
        .A_REN(1'b1),
        .A_BM({16{1'b1}}),
        .A_BIST_EN(1'b0),
        .A_DLY()
    );
        
    memory_power Power (
        .clock(clock),   // 1 bit input: clock signal
        .reset(reset),   // 1 bit input: reset signal
        .on(on),      // 1 bit input: turn on memory
        .ready(ready)    // 1 bit output: memory is powered and ready to use
    );
    
    
endmodule
