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
//        .flush(),
//        .th_low(),      // 
//        .th_high(),     // 
//        .index(),
//        .code_index(), 
//        .distance(),    //
//        .success(),     //
//        .selected_bit() //
//    );
//////////////////////////////////////////////////////////////////////////////////


module selection #(
    MAX_BOOK_SIZE = 32, // maximum number of codewords
    MAX_CODE_SIZE = 15, // maximum size of codewords in bits
    MAX_CYCLES = 10,
    SEQUENCES = 8           // number of sequences processed together
    )(
    clock,
    reset,
    enable,
    flush,
    th_low,
    th_high,
    index,
    code_index,
    distance,
    success,
    selected_bit
    );
    
    
    localparam BOOK_INDX_SIZE = $clog2(MAX_BOOK_SIZE);
    localparam CODE_INDX_SIZE = $clog2(MAX_CODE_SIZE);
    localparam SEQCS_IDX_SIZE = $clog2(SEQUENCES);
    localparam SUM_SIZE = $clog2(MAX_CODE_SIZE*MAX_CYCLES+1);
    input  logic clock;
    input  logic reset;
    input  logic enable;
    input  logic flush;
    input  logic [SUM_SIZE-1:0] th_low;
    input  logic [SUM_SIZE-1:0] th_high;
    input  logic [SEQCS_IDX_SIZE-1:0] index;
    input  logic [BOOK_INDX_SIZE-1:0] code_index;
    input  logic [CODE_INDX_SIZE-1:0] distance;
    output logic success;
    output logic selected_bit;
    
    
    logic [SUM_SIZE-1:0] sums [SEQUENCES-1:0][MAX_BOOK_SIZE-1:0];
    logic [SUM_SIZE-1:0] sums_next [SEQUENCES-1:0][MAX_BOOK_SIZE-1:0];
    logic [SUM_SIZE-1:0] current_sum;
    
    always_ff @(posedge clock) begin
        if(reset) begin
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
        current_sum = sums[index][code_index] + distance;
        if(enable) begin
            if(current_sum <= th_low) begin
                success = 1'b1;
                selected_bit = 1'b1;
            end
            if(current_sum >= th_high) begin
                success = 1'b1;
                selected_bit = 1'b0;
            end
            sums_next[index][code_index] = current_sum;
        end
        if(flush) begin
            for(int i=0; i<SEQUENCES; i++) begin
                for(int j=0; j<MAX_BOOK_SIZE; j++) begin
                    sums_next[i][j] = 0;
                end
            end
        end
    end
    
endmodule
