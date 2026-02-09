`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 09.12.2025
// Design Name: sram_puf
// Module Name: secret_generator
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


///////////////////////////// Instantiation Template /////////////////////////////
//    secret_generator #(
//        .KEY_SIZE(64),  // size of derived key in bits
//        .BOOK_SIZE(32), // number of codewords
//        .CODE_SIZE(15), // size of codewords in bits
//        .THRESHOLD(1),  // 
//        .CYCLES(32),    // number of power-on cycles
//        .WORDS(4)           // number of words read on each powe-on cycle
//        ) instance_name (
//        .clock(),
//        .reset(),
//        .start(),       //
//        .code_index(),  // clog2(MAX_BOOK_SIZE) bits output: codeword selection index
//        .codeword(),    // MAX_CODE_SIZE bits input: selected codeword value
//        .key(),         // MAX_KEY_SIZE bits output: derivated key
//        .done()         // 1 bit input: key is valid
//    );
//////////////////////////////////////////////////////////////////////////////////
    
module secret_generator #(
    KEY_SIZE = 64,  // maximum size of generated key in bits
    BOOK_SIZE = 32, // maximum number of codewords
    CODE_SIZE = 15, // maximum size of codewords in bits
    THRESHOLD = 1,
    CYCLES = 32,     // maximum number of power-on cycles
    WORDS = 4
    )(
    clock,
    reset,
    start,      //
    code_index, // codeword selection index
    codeword,   // selected codeword value
    key,        // derivated key
    done        // key is valid
    );
    
    localparam KEY_INDX_SIZE = $clog2(KEY_SIZE);
    localparam BOOK_INDX_SIZE = $clog2(BOOK_SIZE);
    localparam CODE_INDX_SIZE = $clog2(CODE_SIZE);
    localparam COUNT_SIZE = $clog2(CYCLES);
    localparam DIST_SIZE = $clog2(CODE_SIZE*CYCLES+1);
    localparam TH_LOW = THRESHOLD*CYCLES;
    localparam TH_HIGH = (CODE_SIZE-THRESHOLD)*CYCLES;
    input  logic clock;
    input  logic reset;
    input  logic start;
    output logic [BOOK_INDX_SIZE-1:0] code_index;
    input  logic [CODE_SIZE-1:0] codeword;
    output logic [KEY_SIZE-1:0] key;
    output logic done;
    
    
    localparam WIDTH = 16;
    localparam DEPTH = 1024;
    localparam OVERLAP = (CODE_SIZE-1)/WIDTH + 1;
    localparam WORDS_2 = WORDS + OVERLAP;   // number of words needs to be at least OVERLAP + 1
    localparam ADDRESS_SIZE = $clog2(DEPTH);
    localparam SUM_SIZE = $clog2(CYCLES+1);
    localparam WORD_IDX_SIZE = $clog2(WORDS_2);
    localparam REG_SIZE = WORDS_2 * WIDTH;
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
    logic [SUM_SIZE-1:0] sequence_sums [CODE_SIZE-1:0];
    logic [DIST_SIZE-1:0] distance;
    logic [KEY_INDX_SIZE-1:0] bit_count, bit_count_next;
    logic enable, load, full, last_cycle, shift;
    logic [KEY_SIZE-1:0] key_next;
    logic valid, success;
    logic on, ready;
    assign last_cycle = counter==(CYCLES-1);
    
    always_ff @(posedge clock) begin
        if (reset) begin
            state <= IDLE;
            checkpoint <= 0;
            counter <= 0;
            index <= 0;
            code_index <= 0;
            bit_count <= 0;
            key <= {KEY_SIZE{1'bx}};
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
                    if(word_index < WORDS_2-1)
                        load = 1'b1;
                    if(index + CODE_SIZE <= ((word_index+1)<<BIT_IDX_SIZE)) begin
                        valid = 1'b1;
                        if(code_index == BOOK_SIZE-1) begin
                            code_index_next = 0;
                            if(index + CODE_SIZE >= REG_SIZE) begin
                                counter_next = 0;
                                index_next = index + 1 - (WORDS<<BIT_IDX_SIZE);;
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
                        if(distance<=TH_LOW || distance>=TH_HIGH) begin // selection success
                            success = 1'b1;
                            key_next[bit_count] = (distance<=TH_LOW) ? 1'b1 : 1'b0;
                            if (bit_count==KEY_SIZE-1) begin
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
                                if(index + ((CODE_SIZE-1)<<1) >= REG_SIZE-2) begin
                                    counter_next = 0;
                                    index_next = index + CODE_SIZE - (WORDS<<BIT_IDX_SIZE);
                                    checkpoint_next = address;
                                    shift = 1'b1;
                                    load = 1'b1;
                                end
                                else begin
                                    index_next = index + CODE_SIZE;
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
//                if(start==1'b0) begin
//                    state_next = IDLE;
//                    bit_count_next = 0;
//                    key_next = {KEY_SIZE{1'bx}};
//                end
            end
            default:
                state_next = IDLE;
        endcase
        for(int i=0; i<CODE_SIZE; i++) begin
            sequence_sums[i] = sums[index+i];
        end
    end
    
    
    distance #(
        .CODE_SIZE(CODE_SIZE),   // maximum size of codewords in bits
        .CYCLES(CYCLES)       // maximum number of power-on cycles
        ) Hamming (
        .bit_sums(sequence_sums),    // WORDS*WIDTH array input: current buffer content
        .codeword(codeword),    // MAX_CODE_SIZE bits input: selected codeword value
        .distance(distance)     // 
    );
    
    cumulator #(
        .CYCLES(CYCLES),// 
        .WIDTH(WIDTH),     // memory word size in bits
        .DEPTH(DEPTH),   // memory number of words
        .WORDS(WORDS_2),      // number of words in the shift register
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
