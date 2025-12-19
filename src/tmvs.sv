`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 05.11.2025
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
//        .MAX_CYCLES(32),    // maximum number of power-on cycles
//        .SEQUENCES(32)      // 
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
    MAX_CYCLES = 32,    // maximum number of power-on cycles
    SEQUENCES = 32
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
    localparam SUM_SIZE = $clog2(MAX_CODE_SIZE*MAX_CYCLES+1);
    input  logic clock;
    input  logic reset;
    input  logic start;
    input  logic [KEY_INDX_SIZE-1:0] key_size;
    input  logic [BOOK_INDX_SIZE-1:0] book_size;
    input  logic [CODE_INDX_SIZE-1:0] code_size;
    input  logic [SUM_SIZE-1:0] th_low;
    input  logic [SUM_SIZE-1:0] th_high;
    input  logic [COUNT_SIZE-1:0] cycles;
    output logic [BOOK_INDX_SIZE-1:0] code_index;
    input  logic [MAX_CODE_SIZE-1:0] codeword;
    output logic [MAX_KEY_SIZE-1:0] key;
    output logic done;
    
    
    enum logic [1:0] {IDLE, RUN, OFF, DONE} state, state_next;
    logic [COUNT_SIZE-1:0] counter, counter_next;
    logic [KEY_INDX_SIZE-1:0] bit_count, bit_count_next;
    logic start_segment, last_sequence, last_cycle, advance;
    logic [MAX_KEY_SIZE-1:0] key_next;
    logic success, selected_bit;
    logic on, ready;
    assign last_cycle = counter==cycles;
    
    always_ff @(posedge clock) begin
        if (reset) begin
            state <= IDLE;
            counter <= 0;
            bit_count <= 0;
            key <= {MAX_KEY_SIZE{1'bx}};
        end
        else begin
            state <= state_next;
            counter <= counter_next;
            bit_count <= bit_count_next;
            key <= key_next;
        end
    end
    
    always_comb begin
        state_next = state;
        counter_next = counter;
        bit_count_next = bit_count;
        key_next = key;
        start_segment = 1'b0;
        advance = 1'b0;
        on = 1'b1;
        done = 1'b0;
        case(state)
            IDLE: begin 
                if(start) begin
                    state_next = RUN;
                    start_segment = 1'b1;
                end
            end
            RUN: begin
                if(last_sequence) begin // last segment of sequences
                    counter_next = counter + 1;
                    if(last_cycle) begin // last cycle
                        counter_next = 0;
                        advance = 1'b1;
                    end
                    else begin
                        state_next = OFF;
                        on = 1'b0;
                    end
                end
                if(last_cycle) begin // last cycle
                    if(success) begin
                        key_next[bit_count] = selected_bit;
                        if (bit_count==key_size) begin
                            state_next = DONE;
                            counter_next = 0;
                        end
                        else begin
                            bit_count_next = bit_count + 1;
                        end
                    end
                end
            end
            OFF: begin
                if(ready) begin
                    state_next = RUN;
                    start_segment = 1'b1;
                end
                else begin
                    on = 1'b0;
                end
            end
            DONE: begin
                done = 1'b1;
                if(start==1'b0) begin
                    state_next = IDLE;
                    bit_count_next = 0;
                    key_next = {MAX_KEY_SIZE{1'bx}};
                end
            end
        endcase
    end
      
    
    buffer #(
        .MAX_BOOK_SIZE(MAX_BOOK_SIZE), // maximum number of codewords
        .MAX_CODE_SIZE(MAX_CODE_SIZE), // maximum size of codewords in bits
        .MAX_CYCLES(MAX_CYCLES),    // maximum number of power-on cycles
        .SEQUENCES(SEQUENCES)      // number of sequences processed together
        ) Buffer (
        .clock(clock),       // 1 bit input: clock signal
        .reset(reset||done),       // 1 bit input: reset signal
        .book_size(book_size),   // configured number of codewords
        .code_size(code_size),   // configured codeword size in bits
        .code_index(code_index), 
        .th_low(th_low),
        .th_high(th_high),
        .codeword(codeword),    //
        .start(start_segment),       //
        .last_cycle(last_cycle),
        .last_sequence(last_sequence),
        .success(success),
        .selected_bit(selected_bit)
    );
    
    memory_power Power (
        .clock(clock),   // 1 bit input: clock signal
        .reset(reset),   // 1 bit input: reset signal
        .on(on),      // 1 bit input: turn on memory
        .ready(ready)    // 1 bit output: memory is powered and ready to use
    );
    
    
endmodule
