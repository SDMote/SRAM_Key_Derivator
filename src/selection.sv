`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 18.11.2025
// Design Name: sram_puf
// Module Name: selection
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

///////////////////////////// Instantiation Template /////////////////////////////
//    selection #(
//        .MAX_BOOK_SIZE(32), // maximum number of codewords
//        .MAX_CODE_SIZE(15), // maximum size of codewords in bits
//        .MAX_CYCLES(32),    // maximum number of power-on cycles
//        .SEQUENCES(32),     // number of sequences processed together
//        .SEQUENCE_UNROLL(4) // number of sequences processed in parallel
//        ) instance_name (
//        .clock(),       // 1 bit input: clock signal
//        .reset(),       // 1 bit input: reset signal
//        .enable(),
//        .restart(),
//        .book_size(),   // configured number of codewords
//        .code_size(),   // configured codeword size in bits
//        .th_low(),      // 
//        .th_high(),     // 
//        .index(),
//        .code_index(), 
//        .h_distances(), //
//        .selected_bit() //
//    );
//////////////////////////////////////////////////////////////////////////////////


module selection #(
    MAX_BOOK_SIZE = 32, // maximum number of codewords
    MAX_CODE_SIZE = 15, // maximum size of codewords in bits
    MAX_CYCLES = 10,
    SEQUENCES = 8,          // number of sequences processed together
    SEQUENCE_UNROLL = 4     // number of sequences processed in parallel
    )(
    clock,
    reset,
    enable,
    restart,
    book_size,
    code_size,
    th_low,
    th_high,
    index,
    code_index,
    h_distances,
    success,
    selected_offset,
    selected_bit
    );
    
    
    localparam BOOK_INDX_SIZE = $clog2(MAX_BOOK_SIZE);
    localparam CODE_INDX_SIZE = $clog2(MAX_CODE_SIZE);
    localparam SEQCS_IDX_SIZE = $clog2(SEQUENCES);
    localparam SUM_SIZE = $clog2(MAX_CODE_SIZE*MAX_CYCLES+1);
    localparam SEQ_UNROLL_SIZE = $clog2(SEQUENCE_UNROLL);
    input  logic clock;
    input  logic reset;
    input  logic enable;
    input  logic restart;
    input  logic [BOOK_INDX_SIZE-1:0] book_size;
    input  logic [CODE_INDX_SIZE-1:0] code_size;
    input  logic [SUM_SIZE-1:0] th_low;
    input  logic [SUM_SIZE-1:0] th_high;
    input  logic [SEQCS_IDX_SIZE-1:0] index;
    input  logic [BOOK_INDX_SIZE-1:0] code_index;
    input  logic [CODE_INDX_SIZE-1:0] h_distances [SEQUENCE_UNROLL-1:0];
    output logic success;
    output logic [SEQ_UNROLL_SIZE-1:0] selected_offset;
    output logic selected_bit;
    
    
    logic [SUM_SIZE-1:0] sums [SEQUENCES-1:0][MAX_BOOK_SIZE-1:0];
    logic [SUM_SIZE-1:0] sums_next [SEQUENCES-1:0][MAX_BOOK_SIZE-1:0];
    
    always_ff @(posedge clock) begin
        if (reset) begin
            for(int i=0; i<SEQUENCES; i++) begin
                for(int j=0; j<MAX_BOOK_SIZE; j++) begin
                    sums[i][j] <= 0;
                end
            end
        end
        else begin
            sums <= sums_next;
        end
    end
    
    always_comb begin
        sums_next = sums;
        success = 1'b0;
        selected_bit = 1'bx;
        if(enable) begin
            for(int i=0; i<SEQUENCE_UNROLL; i++) begin
                sums_next[index+i][code_index] = sums[index+i][code_index] + h_distances[i];
                if(success == 1'b0) begin
                    if(sums_next[index+i][code_index] <= th_low) begin
                        success = 1'b1;
                        selected_offset = i;
                        selected_bit = 1'b0;
                    end
                    if(sums_next[index+i][code_index] >= th_high) begin
                        success = 1'b1;
                        selected_offset = i;
                        selected_bit = 1'b1;
                    end
                end
            end
        end
        if(restart) begin
            for(int i=0; i<SEQUENCES; i++) begin
                for(int j=0; j<MAX_BOOK_SIZE; j++) begin
                    sums_next[i][j] = 0;
                end
            end
        end
        
    end
    
endmodule
