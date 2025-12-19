`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 06.11.2025
// Design Name: sram_puf
// Module Name: buffer
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


///////////////////////////// Instantiation Template /////////////////////////////
//    buffer #(
//        .MAX_BOOK_SIZE(32), // maximum number of codewords
//        .MAX_CODE_SIZE(15), // maximum size of codewords in bits
//        .MAX_CYCLES(32),    // maximum number of power-on cycles
//        .SEQUENCES(32)      // number of sequences processed together
//        ) instance_name (
//        .clock(),       // 1 bit input: clock signal
//        .reset(),       // 1 bit input: reset signal
//        .book_size(),   // configured number of codewords
//        .code_size(),   // configured codeword size in bits
//        .code_index(), 
//        .th_low(),   // 
//        .th_high(),   // 
//        .codeword(),    //
//        .start(),       //
//        .last_cycle(),
//        .last_sequence(),
//        .success(),
//        .selected_bit() 
//    );
//////////////////////////////////////////////////////////////////////////////////

module buffer #(
    MAX_BOOK_SIZE = 32, // maximum number of codewords
    MAX_CODE_SIZE = 15, // maximum size of codewords in bits
    MAX_CYCLES = 10,
    SEQUENCES = 8           // number of sequences processed together
    )(
    clock,
    reset,
    book_size,  // configured number of codewords
    code_size,  // configured codeword size in bits
    code_index, // codeword selection index
    th_low,
    th_high,
    codeword,   // selected codeword value
    start,
    last_cycle,
    last_sequence,
    success,
    selected_bit
    );
    
    localparam WIDTH = 16;      // memory word size in bits
    localparam DEPTH = 1024;    // memory number of words
    localparam ADDRESS_SIZE = $clog2(DEPTH);
    localparam BOOK_INDX_SIZE = $clog2(MAX_BOOK_SIZE);
    localparam CODE_INDX_SIZE = $clog2(MAX_CODE_SIZE);
    localparam SEQCS_IDX_SIZE = $clog2(SEQUENCES);
    localparam SUM_SIZE = $clog2(MAX_CODE_SIZE*MAX_CYCLES+1);
    input  logic clock;
    input  logic reset;
    input  logic [BOOK_INDX_SIZE-1:0] book_size;
    input  logic [CODE_INDX_SIZE-1:0] code_size;
    input  logic [SUM_SIZE-1:0] th_low;
    input  logic [SUM_SIZE-1:0] th_high;
    output logic [BOOK_INDX_SIZE-1:0] code_index;
    input  logic [MAX_CODE_SIZE-1:0] codeword;
    input  logic start;
    input  logic last_cycle;
    output logic last_sequence;
    output logic success;
    output logic selected_bit;
    
    
    localparam WORDS = 2 + (MAX_CODE_SIZE-1) / WIDTH;
    localparam WORD_INDX_SIZE = $clog2(WORDS);
    localparam BITS = WORDS * WIDTH;
    localparam DATA_INDX_SIZE = $clog2(WIDTH);
    localparam SHIFT_COUNT_SIZE = $clog2(WIDTH+MAX_CODE_SIZE-1)-DATA_INDX_SIZE;
    enum logic [2:0] {IDLE, FILL, RUN, STOP, SHIFT} state, state_next;
    logic [ADDRESS_SIZE-1:0] address;   // memory address
    logic [WIDTH-1:0] read_data;             // memory read data
    logic [BITS-1:0] shift_reg;
    logic [BOOK_INDX_SIZE-1:0] code_index_next;
    logic [SEQCS_IDX_SIZE-1:0] index, index_next;
    logic [MAX_CODE_SIZE-1:0] readout, offseted_reg;
    logic [DATA_INDX_SIZE-1:0] offset, offset_next;
    logic [ADDRESS_SIZE+DATA_INDX_SIZE-1:0] checkpoint, checkpoint_next;
    logic fill;
    logic shift;
    logic full;
    logic flush;
    logic [CODE_INDX_SIZE-1:0] distance;
    
    
    logic raw_success;
    logic [SHIFT_COUNT_SIZE-1:0] shift_number;
    logic [SHIFT_COUNT_SIZE-1:0] shift_count, shift_count_next;
    
    always_ff @(posedge clock) begin
        if (reset) begin
            state <= IDLE;
            offset <= 0;
            index <= 0;
            code_index <= 0;
            checkpoint <= 0;
            shift_count <= 0;
        end
        else begin
            state <= state_next;
            offset <= offset_next; 
            index <= index_next;
            code_index <= code_index_next;
            checkpoint <= checkpoint_next;
            shift_count <= shift_count_next;
        end
    end
    
    
    always_comb begin
        state_next = state;
        offset_next = offset;
        index_next = index;
        code_index_next = code_index;
        checkpoint_next = checkpoint;
        shift_count_next = shift_count;
        fill = 1'b0;
        shift = 1'b0;
        shift_number = 0;
        last_sequence = 1'b0;
        flush = 1'b0;
        case(state)
            IDLE: begin 
                if(start) begin
                    state_next = FILL;
                    fill = 1'b1;
                end
            end
            FILL: begin
                if(full) begin
                    state_next = RUN;
                    code_index_next = 0;
                end
            end
            RUN: begin
                if(code_index == book_size) begin
                    code_index_next = 0;
                    if(index >= SEQUENCES - 1) begin
                        index_next = 0;
                        last_sequence = 1'b1;
                        if(last_cycle) begin
                            {shift_number, offset_next} = offset + 1; 
                            checkpoint_next = checkpoint + SEQUENCES;   // update checkpoint
                            flush = 1'b1;
                            if(offset >= WIDTH - 1) begin // offset expected to overflow
                                shift = 1'b1;
                            end
                        end
                        else begin
                            state_next = STOP;
                            offset_next = checkpoint[DATA_INDX_SIZE-1:0];
                        end
                    end
                    else begin
                        offset_next = offset + 1; 
                        index_next = index + 1;
                        if(offset >= WIDTH - 1) begin // offset expected to overflow
                            shift = 1'b1;
                        end
                    end
                end
                else begin
                    code_index_next = code_index + 1;
                end
                if(success) begin
                    code_index_next = 0;
                    {shift_number, offset_next} = offset + code_size + 1; 
                    if(index + code_size + 1 >= SEQUENCES) begin
                        index_next = 0;
                        last_sequence = 1'b1;
                        checkpoint_next = checkpoint + index + code_size + 1;   // update checkpoint
                        flush = 1'b1;                     
                    end
                    else begin
                        index_next = index + code_size + 1;
                    end 
                end
                if(shift_number >= 1) begin
                    shift = 1'b1;
                    if(shift_number > 1) begin
                        state_next = SHIFT;
                        shift_count_next = shift_number - 2;
                    end
                end  
            end
            STOP: begin
                if(start) begin
                    state_next = FILL;
                    fill = 1'b1;
                end
                
            end
            SHIFT: begin
                shift = 1'b1;
                shift_count_next = shift_count - 1;
                if(shift_count == 0) begin
                    state_next = RUN;
                end
            end
            default: begin
                state_next = IDLE;
            end            
        endcase            
    end
    
    assign offseted_reg = shift_reg >> offset;
    assign readout = offseted_reg[MAX_CODE_SIZE-1:0];
    assign success = raw_success && last_cycle;
    
    
    selection #(
        .MAX_BOOK_SIZE(MAX_BOOK_SIZE), // maximum number of codewords
        .MAX_CODE_SIZE(MAX_CODE_SIZE), // maximum size of codewords in bits
        .MAX_CYCLES(MAX_CYCLES),    // maximum number of power-on cycles
        .SEQUENCES(SEQUENCES)      // number of sequences processed together
        ) Selector (
        .clock(clock),       // 1 bit input: clock signal
        .reset(reset),       // 1 bit input: reset signal
        .enable(state==RUN),
        .flush(flush),
        .th_low(th_low),
        .th_high(th_high),
        .index(index),
        .code_index(code_index), 
        .distance(distance),    //
        .success(raw_success),
        .selected_bit(selected_bit)       //
    );
    
    logic [MAX_CODE_SIZE-1:0] mask;
    assign mask = ~({MAX_CODE_SIZE{1'b1}} << (code_size + 1));
    hamming_distance #(
        .WIDTH(MAX_CODE_SIZE)
        ) Hamming (
        .A(mask & readout),       //
        .B(mask & codeword),       //
        .distance(distance) // 
    );

    shift_register #(
        .WIDTH(WIDTH),     // memory word size in bits
        .DEPTH(DEPTH),   // memory number of words
        .WORDS(WORDS)       // number of words in the shift register
        ) Shifter (
        .clock(clock),       // 1 bit input: clock signal
        .reset(reset),       // 1 bit input: reset signal
        .address(address),     // clog2(WIDTH) bits output: memory address
        .data(read_data),        // WIDTH bits input: memory data
        .checkpoint(checkpoint[ADDRESS_SIZE+DATA_INDX_SIZE-1:DATA_INDX_SIZE]),  // WIDTH bits input: address checkpoint to start loading from
        .shift_reg(shift_reg),   // WORDS*WIDTH bits output: current shift register content
        .fill(fill),        // 1 bit input: go to checkpoint address and fill shift register
        .shift(shift),       // 1 bit input: load a new word into the dhift register
        .full(full)         // 1 bit output: shift register is full
    );
    
    RM_IHPSG13_1P_1024x16_c2_bm_bist Memory (
        .A_ADDR(address),
        .A_CLK(clock),
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
