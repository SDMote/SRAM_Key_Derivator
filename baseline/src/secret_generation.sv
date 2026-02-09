`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 05.11.2025
// Design Name: sram_puf
// Module Name: secret_generation
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


///////////////////////////// Instantiation Template /////////////////////////////
//    secret_generation #(
//        .KEY_SIZE(64),  // size of derived key in bits
//        .BOOK_SIZE(32), // number of codewords
//        .CODE_SIZE(15), // size of codewords in bits
//        .THRESHOLD(0),  // 
//        .CYCLES(32),    // number of power-on cycles
//        .SEQUENCES(32)      // 
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
    
module secret_generation #(
    KEY_SIZE = 64,  // maximum size of generated key in bits
    BOOK_SIZE = 32, // maximum number of codewords
    CODE_SIZE = 15, // maximum size of codewords in bits
    THRESHOLD = 0,
    CYCLES = 32,    // maximum number of power-on cycles
    SEQUENCES = 32
    )(
    clock,
    reset,
    start,      //
    code_index, // codeword selection index
    codeword,   // selected codeword value
    key,        // derivated key
    done        // key is valid
    );
    
    localparam WIDTH = 16;
    localparam DEPTH = 1024;
    localparam KEY_INDX_SIZE = $clog2(KEY_SIZE);
    localparam BOOK_INDX_SIZE = $clog2(BOOK_SIZE);
    localparam CODE_INDX_SIZE = $clog2(CODE_SIZE);
    localparam COUNT_SIZE = $clog2(CYCLES);
    localparam SUM_SIZE = $clog2(CODE_SIZE*CYCLES+1);
    localparam ADDRESS_SIZE = $clog2(DEPTH);
    input  logic clock;
    input  logic reset;
    input  logic start;
    output logic [BOOK_INDX_SIZE-1:0] code_index;
    input  logic [CODE_SIZE-1:0] codeword;
    output logic [KEY_SIZE-1:0] key;
    output logic done;
    
    
    enum logic [1:0] {IDLE, RUN, OFF, DONE} state, state_next;
    logic [ADDRESS_SIZE-1:0] address;   // memory address
    logic [WIDTH-1:0] read_data;             // memory read data
    logic [COUNT_SIZE-1:0] counter, counter_next;
    logic [KEY_INDX_SIZE-1:0] bit_count, bit_count_next;
    logic start_segment, last_sequence, last_cycle, advance;
    logic [KEY_SIZE-1:0] key_next;
    logic success, selected_bit;
    logic on, ready;
    assign last_cycle = counter==(CYCLES-1);
    
    always_ff @(posedge clock) begin
        if (reset) begin
            state <= IDLE;
            counter <= 0;
            bit_count <= 0;
            key <= {KEY_SIZE{1'bx}};
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
                        if (bit_count==KEY_SIZE - 1) begin
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
//                if(start==1'b0) begin
//                    state_next = IDLE;
//                    bit_count_next = 0;
//                    key_next = {KEY_SIZE{1'bx}};
//                end
            end
        endcase
    end
      
    
    buffer #(
        .WIDTH(WIDTH),     // memory word size in bits
        .DEPTH(DEPTH),   // memory number of words
        .BOOK_SIZE(BOOK_SIZE), // maximum number of codewords
        .CODE_SIZE(CODE_SIZE), // maximum size of codewords in bits
        .THRESHOLD(THRESHOLD),      // 
        .CYCLES(CYCLES),    // maximum number of power-on cycles
        .SEQUENCES(SEQUENCES)      // number of sequences processed together
        ) Buffer (
        .clock(clock),       // 1 bit input: clock signal
        .reset(reset||done),       // 1 bit input: reset signal
        .address(address),     // 
        .read_data(read_data),   // 
        .code_index(code_index), 
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
