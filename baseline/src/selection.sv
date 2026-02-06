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
//        .BOOK_SIZE(32),     // number of codewords
//        .CODE_SIZE(15),     // size of codewords in bits
//        .THRESHOLD(0),      // 
//        .CYCLES(32),        // number of power-on cycles
//        .SEQUENCES(32)      // number of sequences processed together
//        ) instance_name (
//        .clock(),       // 1 bit input: clock signal
//        .reset(),       // 1 bit input: reset signal
//        .enable(),
//        .flush(),
//        .index(),
//        .code_index(), 
//        .distance(),    //
//        .success(),     //
//        .selected_bit() //
//    );
//////////////////////////////////////////////////////////////////////////////////


module selection #(
    BOOK_SIZE = 32, // maximum number of codewords
    CODE_SIZE = 15, // maximum size of codewords in bits
    THRESHOLD = 0,
    CYCLES = 10,
    SEQUENCES = 8           // number of sequences processed together
    )(
    clock,
    reset,
    enable,
    flush,
    index,
    code_index,
    distance,
    success,
    selected_bit
    );
    
    
    localparam BOOK_INDX_SIZE = $clog2(BOOK_SIZE);
    localparam CODE_INDX_SIZE = $clog2(CODE_SIZE);
    localparam SEQCS_IDX_SIZE = $clog2(SEQUENCES);
    localparam SUM_SIZE = $clog2(CODE_SIZE*CYCLES+1);
    localparam TH_LOW = THRESHOLD*CYCLES;
    localparam TH_HIGH = (CODE_SIZE-THRESHOLD)*CYCLES;
    input  logic clock;
    input  logic reset;
    input  logic enable;
    input  logic flush;
    input  logic [SEQCS_IDX_SIZE-1:0] index;
    input  logic [BOOK_INDX_SIZE-1:0] code_index;
    input  logic [CODE_INDX_SIZE-1:0] distance;
    output logic success;
    output logic selected_bit;
    
    
    logic [SUM_SIZE-1:0] sums [SEQUENCES-1:0][BOOK_SIZE-1:0];
    logic [SUM_SIZE-1:0] sums_next [SEQUENCES-1:0][BOOK_SIZE-1:0];
    logic [SUM_SIZE-1:0] current_sum;
    
    always_ff @(posedge clock) begin
        if(reset) begin
            for(int i=0; i<SEQUENCES; i++) begin
                for(int j=0; j<BOOK_SIZE; j++) begin
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
            if(current_sum <= TH_LOW) begin
                success = 1'b1;
                selected_bit = 1'b1;
            end
            if(current_sum >= TH_HIGH) begin
                success = 1'b1;
                selected_bit = 1'b0;
            end
            sums_next[index][code_index] = current_sum;
        end
        if(flush) begin
            for(int i=0; i<SEQUENCES; i++) begin
                for(int j=0; j<BOOK_SIZE; j++) begin
                    sums_next[i][j] = 0;
                end
            end
        end
    end
    
endmodule
