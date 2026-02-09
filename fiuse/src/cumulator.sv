`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 10.12.2025
// Design Name: sram_puf
// Module Name: cumulator
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


///////////////////////////// Instantiation Template /////////////////////////////
//    cumulator #(
//        .CYCLES(10),    // 
//        .WIDTH(16),     // memory word size in bits
//        .DEPTH(1024),   // memory number of words
//        .WORDS(4),      // number of words in the shift register
//        .OVERLAP(1)     // number of words to keep from the back of the register when shifting
//        ) DUT (
//        .clock(),       // 1 bit input: clock signal
//        .reset(),       // 1 bit input: reset signal
//        .enable(),      // 1 bit input: reset signal
//        .address(),     // clog2(WIDTH) bits output: memory address
//        .data(),        // WIDTH bits input: memory data
//        .word_index(),  // position currently updating
//        .sums(),        // WORDS*WIDTH array output: current buffer content
//        .checkpoint(),  // WIDTH bits input: address checkpoint to start loading from
//        .load(),        // 1 bit input: load a new word into the shift register
//        .shift(),       // 1 bit input: clear registers, update checkpoint and continue
//        .full()         // 1 bit output: shift register is full
//    );   
//////////////////////////////////////////////////////////////////////////////////

module cumulator #(
    CYCLES = 10,
    WIDTH = 16,         // memory word size in bits
    DEPTH = 1024,       // memory number of words
    WORDS = 2,          // 
    OVERLAP = 1         //
    )(
    clock,
    reset,
    enable,
    address,    // memory address
    data,       // memory data
    sums,
    word_index,
    checkpoint, //
    load,
    shift,
    full
    );
    
    localparam ADDRESS_SIZE = $clog2(DEPTH);
    localparam SUM_SIZE = $clog2(CYCLES+1);
    localparam REG_SIZE = WORDS * WIDTH;
    localparam BIT_IDX_SIZE = $clog2(WIDTH);
    localparam WORD_IDX_SIZE = $clog2(WORDS);
    localparam REG_IDX_SIZE = $clog2(REG_SIZE);
    input  logic clock;
    input  logic reset;
    input  logic enable;
    output logic [ADDRESS_SIZE-1:0] address;
    input  logic [WIDTH-1:0] data;
    output logic [SUM_SIZE-1:0] sums [REG_SIZE-1:0];
    output logic [WORD_IDX_SIZE-1:0] word_index;
    input  logic [ADDRESS_SIZE-1:0] checkpoint;
    input  logic load;
    input  logic shift;
    output logic full;
    
    enum logic [1:0]{IDLE, LOAD, STOP} state, state_next;
    logic [SUM_SIZE-1:0] sums_next [REG_SIZE-1:0];
    logic [SUM_SIZE-1:0] sums_prev [REG_SIZE-1:0];
    logic [ADDRESS_SIZE-1:0] address_prev;
    logic [WORD_IDX_SIZE-1:0] word_index_next;
    logic [REG_IDX_SIZE-1:0] reg_index;
    logic first, first_next;
    
    
    always_ff @(posedge clock) begin
        if(reset) begin
            state <= IDLE;
            address_prev <= {DEPTH{1'b0}};
            word_index <= 0;
            first <= 1'b1;
            for(int i=0; i<REG_SIZE; i++) begin
                 sums_prev[i] <= 0;
            end
        end
        else begin
            state <= state_next;
            address_prev <= address;
            word_index <= word_index_next;
            sums_prev <= sums_next;
            first <= first_next;
        end
    end
    
    always_comb begin
        state_next = state;
        address = address_prev;
        word_index_next = word_index;
        sums = sums_prev;
        sums_next = sums_prev;
        first_next = first;
        full = 1'b0;
        case(state)
            IDLE: begin
                first_next = 1'b1;
                address = checkpoint;
                word_index_next = 0;
                for(int i=0; i<REG_SIZE; i++) begin
                     sums_next[i] = 0;
                end
                if(enable)
                    state_next = LOAD;
            end
            LOAD: begin
                for(int i=0; i<WIDTH; i++) begin
                    sums[reg_index+i] = sums_prev[reg_index+i] + data[i];  
                end
                if(load) begin     // add bits of the next word 
                    sums_next = sums;
                    if(word_index >= WORDS-1) begin   // if last word
                        word_index_next = (first==1'b1 && shift==1'b0) ? 0 : OVERLAP;
                        full = 1'b1;
                        if(shift) begin       // clear sums and advance
                            address = address_prev + 1;
                            if(first) begin
                                first_next = 1'b0;
                            end
                            for(int j=0; j<OVERLAP; j++) begin
                                for(int i=0; i<WIDTH; i++) begin
                                    sums_next[(j<<BIT_IDX_SIZE)+i] = sums[((WORDS-OVERLAP+j)<<BIT_IDX_SIZE)+i];  
                                end
                            end
                            for(int i=(OVERLAP<<BIT_IDX_SIZE); i<REG_SIZE; i++) begin
                                    sums_next[i] = 0;  
                            end
                        end
                        else begin      // stop for SRAM restart 
                            state_next = STOP;
                            address = checkpoint;
                        end
                    end
                    else begin
                        address = address_prev + 1;
                        word_index_next = word_index + 1;
                    end
                end
            end
            STOP: begin
                full = 1'b1;
                if(load) begin
                    state_next = LOAD;
                end
            end
            default:
                state_next = IDLE;
        endcase
        if(enable == 1'b0)
            state_next = IDLE;
    end
    
    assign reg_index = {word_index, {BIT_IDX_SIZE{1'b0}}};
    
endmodule
