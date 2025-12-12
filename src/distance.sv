`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 10.12.2025
// Design Name: sram_puf
// Module Name: distance
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

///////////////////////////// Instantiation Template /////////////////////////////
//    distance #(
//        .MAX_CODE_SIZE(15), // maximum size of codewords in bits
//        .MAX_CYCLES(32)     // maximum number of power-on cycles
//        ) instance_name (
//        .bit_sums(),    // WORDS*WIDTH array input: current buffer content
//        .codeword(),    // MAX_CODE_SIZE bits input: selected codeword value
//        .code_size(),   // configured codeword size in bits
//        .cycles(),      // configured number of power-on cycles
//        .distance()     // 
//    );
//////////////////////////////////////////////////////////////////////////////////

module distance #(
    MAX_CODE_SIZE = 15, // maximum size of codewords in bits
    MAX_CYCLES = 10
    )(
    bit_sums,
    codeword,
    code_size,
    cycles,
    distance
    );
    
    localparam CODE_INDX_SIZE = $clog2(MAX_CODE_SIZE);
    localparam COUNT_SIZE = $clog2(MAX_CYCLES);
    localparam DIST_SIZE = $clog2(MAX_CODE_SIZE*MAX_CYCLES+1);
    localparam SUM_SIZE = $clog2(MAX_CYCLES+1);
    input  logic [SUM_SIZE-1:0] bit_sums [MAX_CODE_SIZE-1:0];
    input  logic [MAX_CODE_SIZE-1:0] codeword;
    input  logic [CODE_INDX_SIZE-1:0] code_size;
    input  logic [COUNT_SIZE-1:0] cycles;
    output logic [DIST_SIZE-1:0] distance;
        
    always_comb begin
        distance = 0;
        for(int i=0; i<MAX_CODE_SIZE; i++) begin
            if(i <= code_size) begin
                if(codeword[i]==1'b0)
                    distance = distance + bit_sums[i];
                else 
                    distance = distance + (cycles+1 - bit_sums[i]);
            end
        end
    end    
    
endmodule
