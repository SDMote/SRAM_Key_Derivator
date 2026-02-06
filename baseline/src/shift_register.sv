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
//    shift_register #(
//        .WIDTH(16),     // memory word size in bits
//        .DEPTH(1024),   // memory number of words
//        .WORDS(2)       // number of words in the shift register
//        ) instance_name (
//        .clock(),       // 1 bit input: clock signal
//        .reset(),       // 1 bit input: reset signal
//        .address(),     // clog2(WIDTH) bits output: memory address
//        .data(),        // WIDTH bits input: memory data
//        .checkpoint(),  // WIDTH bits input: address checkpoint to start loading from
//        .shift_reg(),   // WORDS*WIDTH bits output: current shift register content
//        .fill(),        // 1 bit input: go to checkpoint address and fill shift register
//        .shift(),       // 1 bit input: load a new word into the dhift register
//        .full()         // 1 bit output: shift register is full
//    );
//////////////////////////////////////////////////////////////////////////////////

module shift_register #(
    WIDTH = 16,         // memory word size in bits
    DEPTH = 1024,       // memory number of words
    WORDS = 2           // number of words in the shift register
    )(
    clock,
    reset,
    address,    // memory address
    data,       // memory data
    shift_reg,  //
    checkpoint, //
    fill,       //
    shift,      //
    full        //
    );
    
    localparam ADDRESS_SIZE = $clog2(DEPTH);
    localparam WORD_INDX_SIZE = $clog2(WORDS);
    localparam BITS = WORDS * WIDTH;
    input  logic clock;
    input  logic reset;
    output logic [ADDRESS_SIZE-1:0] address;
    input  logic [WIDTH-1:0] data;
    input  logic [ADDRESS_SIZE-1:0] checkpoint;
    output logic [BITS-1:0] shift_reg;
    input  logic fill;
    input  logic shift;
    output logic full;
    
    enum logic [1:0] {IDLE, FILL, LOAD, SET} state, state_next;
    logic [WORDS-1:0][WIDTH-1:0] buffer, buffer_next;
    logic [ADDRESS_SIZE-1:0] address_prev;
    logic [WORD_INDX_SIZE-1:0] counter, counter_next;
    
    always_ff @(posedge clock) begin
        if (reset) begin
            state <= IDLE;
            buffer <= {BITS{1'b0}};
            address_prev <= 0;
            counter <= 0;
        end
        else begin
            state <= state_next;
            buffer <= buffer_next;
            address_prev <= address;
            counter <= counter_next;
        end
    end
    
    always_comb begin
        state_next = state;
        buffer_next = buffer;
        address = address_prev;
        counter_next = counter;
        full = 1'b0;
        case(state)
            IDLE: begin 
                address = checkpoint;
                counter_next = 0;
                if(fill) begin
                    state_next = FILL;
                end
            end
            FILL: begin
                address = address_prev + 1;
                counter_next = counter + 1;
                buffer_next = {data, buffer[WORDS-1:1]};
                if(counter == WORDS-1) begin
                    state_next = LOAD;
                    full = 1'b1;
                end
            end
            LOAD: begin
                full = 1'b1;
                if(shift) begin
                    address = address_prev + 1;
                    buffer_next = {data, buffer[WORDS-1:1]};
                end
                if(fill) begin
                    state_next = FILL;
                    counter_next = 0;
                    address = checkpoint;
                end
            end
        endcase
    end
    
    assign shift_reg = buffer;
    
endmodule
