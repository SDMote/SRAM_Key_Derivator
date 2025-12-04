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
//        .SEQUENCES(32),     // number of sequences processed together
//        .SEQUENCE_UNROLL(4) // number of sequences processed in parallel
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
//        .last(),
//    );
//////////////////////////////////////////////////////////////////////////////////

module buffer #(
    MAX_BOOK_SIZE = 32, // maximum number of codewords
    MAX_CODE_SIZE = 15, // maximum size of codewords in bits
    MAX_CYCLES = 10,
    SEQUENCES = 8,          // number of sequences processed together
    SEQUENCE_UNROLL = 4     // number of sequences processed in parallel
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
//    input  logic advance;
    output logic success;
    output logic selected_bit;
    
    
    localparam MAX_READOUT_SIZE = MAX_CODE_SIZE + SEQUENCE_UNROLL - 1;
    localparam WORDS = 2 + (MAX_READOUT_SIZE-1) / WIDTH;
    localparam WORD_INDX_SIZE = $clog2(WORDS);
    localparam BITS = WORDS * WIDTH;
    localparam DATA_INDX_SIZE = $clog2(WIDTH);
    localparam SEQ_UNROLL_SIZE = $clog2(SEQUENCE_UNROLL);
    localparam SHIFT_COUNT_SIZE = $clog2(WIDTH+MAX_CODE_SIZE-1)-DATA_INDX_SIZE;
    enum logic [2:0] {IDLE, FILL, RUN, STOP, SHIFT} state, state_next;
    logic [ADDRESS_SIZE-1:0] address;   // memory address
    logic [WIDTH-1:0] read_data;             // memory read data
    logic [BITS-1:0] shift_reg;
    logic [BOOK_INDX_SIZE-1:0] code_index_next;
//    logic [SUM_SIZE-1:0] sums [SEQUENCES-1:0][MAX_BOOK_SIZE-1:0];
//    logic [SUM_SIZE-1:0] sums_next [SEQUENCES-1:0][MAX_BOOK_SIZE-1:0];
    logic [SEQCS_IDX_SIZE-1:0] index, index_next;
    logic [MAX_READOUT_SIZE-1:0] readout, offseted_reg;
    logic [DATA_INDX_SIZE-1:0] offset, offset_next;
    logic [ADDRESS_SIZE+DATA_INDX_SIZE-1:0] checkpoint, checkpoint_next;
    logic fill;
    logic shift;
    logic full;
    logic restart;
    logic [CODE_INDX_SIZE-1:0] h_distances [SEQUENCE_UNROLL-1:0];
    logic [SEQ_UNROLL_SIZE-1:0] selected_offset;
    
    // TODO: this module should readout a group of X sequences, then advance X bits to the next group, providing signals to load a new word into the shift register 
    // not concerned about power on cycles
    
    logic raw_success;
    logic discard, discard_next;
    logic [CODE_INDX_SIZE-1:0] discard_count, discard_count_next;
    logic [SHIFT_COUNT_SIZE-1:0] shift_number;
    logic [SHIFT_COUNT_SIZE-1:0] shift_count, shift_count_next;
    
    always_ff @(posedge clock) begin
        if (reset) begin
            state <= IDLE;
            offset <= 0;
            index <= 0;
            code_index <= 0;
            checkpoint <= 0;
            for(int i=0; i<SEQUENCES; i++) begin
                for(int j=0; j<MAX_BOOK_SIZE; j++) begin
                end
            end
            discard <= 1'b0;
            discard_count <= 0;
            shift_count <= 0;
        end
        else begin
            state <= state_next;
            offset <= offset_next; 
            index <= index_next;
            code_index <= code_index_next;
            checkpoint <= checkpoint_next;
            discard_count <= discard_count_next;
            discard <= discard_next;
            shift_count <= shift_count_next;
        end
    end
    
    
    always_comb begin
        state_next = state;
        offset_next = offset;
        index_next = index;
        code_index_next = code_index;
        checkpoint_next = checkpoint;
        discard_next = discard;
        discard_count_next = discard_count;
        shift_count_next = shift_count;
        fill = 1'b0;
        shift = 1'b0;
        shift_number = 0;
        last_sequence = 1'b0;
        restart = 1'b0;
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
                    if(discard) begin
                        if(discard_count + 4 >= code_size) begin
                            discard_count_next = 0;
                            discard_next = 1'b0;
                        end
                        else begin
                            discard_count_next = discard_count + 4;
                        end
                    end
                    if(index + SEQUENCE_UNROLL >= SEQUENCES) begin
                        index_next = 0;
                        last_sequence = 1'b1;
                        if(last_cycle) begin
                            {shift_number, offset_next} = offset + SEQUENCE_UNROLL; 
                            checkpoint_next = {address+shift_number-WORDS, offset_next};   // update checkpoint
                            restart = 1'b1;
                            if(offset + SEQUENCE_UNROLL >= WIDTH) begin // offset expected to overflow
                                shift = 1'b1;
                            end
                        end
                        else begin
                            state_next = STOP;
                            offset_next = checkpoint[DATA_INDX_SIZE-1:0];
                        end
                    end
                    else begin
                        offset_next = offset + SEQUENCE_UNROLL; 
                        index_next = index + SEQUENCE_UNROLL;
                        if(offset + SEQUENCE_UNROLL >= WIDTH) begin // offset expected to overflow
                            shift = 1'b1;
                        end
                    end
                end
                else begin
                    code_index_next = code_index + 1;
                end
                if(success) begin
                    if(index + selected_offset + code_size + 1 >= SEQUENCES) begin
                        code_index_next = 0;
                        index_next = 0;
                        last_sequence = 1'b1;
                        {shift_number, offset_next} = offset + selected_offset + code_size + 1; 
                        checkpoint_next = {address+shift_number-WORDS, offset_next};   // update checkpoint
                        restart = 1'b1;
                        if(shift_number >= 1) begin // offset expected to overflow
                            shift = 1'b1;
                            if(shift_number > 1) begin // offset expected to overflow
                                state_next = SHIFT;
                                shift_count_next = shift_number - 2;
                            end
                        end                        
                    end
                    else begin
                        discard_next = 1'b1;
                        if(code_index == book_size)
                            discard_count_next = selected_offset + 4;
                        else
                            discard_count_next = selected_offset;
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
    assign readout = offseted_reg[MAX_READOUT_SIZE-1:0];
    assign success = raw_success && last_cycle && !discard;
    
    
    selection #(
        .MAX_BOOK_SIZE(MAX_BOOK_SIZE), // maximum number of codewords
        .MAX_CODE_SIZE(MAX_CODE_SIZE), // maximum size of codewords in bits
        .MAX_CYCLES(MAX_CYCLES),    // maximum number of power-on cycles
        .SEQUENCES(SEQUENCES),     // number of sequences processed together
        .SEQUENCE_UNROLL(SEQUENCE_UNROLL) // number of sequences processed in parallel
        ) Selector (
        .clock(clock),       // 1 bit input: clock signal
        .reset(reset),       // 1 bit input: reset signal
        .enable(state==RUN),
        .restart(restart),
        .book_size(book_size),   // configured number of codewords
        .code_size(code_size),   // configured codeword size in bits
        .th_low(th_low),
        .th_high(th_high),
        .index(index),
        .code_index(code_index), 
        .h_distances(h_distances),    //
        .success(raw_success),
        .selected_offset(selected_offset),
        .selected_bit(selected_bit)       //
    );
    
    unrolled_hamming #(
        .MAX_CODE_SIZE(MAX_CODE_SIZE),     // maximum size of codewords in bits
        .SEQUENCE_UNROLL(SEQUENCE_UNROLL)     // number of sequences processed together
        ) Hamming (
        .code_size(code_size),   // configured codeword size in bits
        .codeword(codeword),    // selected codeword value to calculate distance
        .readout(readout),     // read sequences
        .distances(h_distances)    // calculated hamming distances
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
    
    RM_IHPSG13_1P_1024x16_c2_bm_bist sram (
        .A_ADDR(address),
        .A_CLK(clock),
        .A_DIN('d0),
        .A_DOUT(read_data),
        .A_MEN(1'b1),
        .A_WEN(1'b0),
        .A_REN(1'b1),
        .A_BM({16{1'b1}}),
        .A_BIST_EN(1'b0),
        .A_DLY()
    );
    
endmodule
