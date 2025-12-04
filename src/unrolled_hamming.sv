`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 13.11.2025
// Design Name: sram_puf
// Module Name: unrolled_hamming
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

///////////////////////////// Instantiation Template /////////////////////////////
//    unrolled_hamming #(
//        .MAX_CODE_SIZE(15),     // maximum size of codewords in bits
//        .SEQUENCE_UNROLL(4)     // number of sequences processed together
//        ) instance_name (
//        .code_size(),   // configured codeword size in bits
//        .codeword(),    // selected codeword value to calculate distance
//        .readout(),     // read sequences
//        .distances()    // calculated hamming distances
//    );
//////////////////////////////////////////////////////////////////////////////////

module unrolled_hamming #(
    MAX_CODE_SIZE = 15, // maximum size of codewords in bits
    SEQUENCE_UNROLL = 4     // number of sequences processed in parallel
    )(
    code_size,  // configured codeword size in bits
    codeword,   // selected codeword value
    readout,
    distances
    );
    
    localparam CODE_INDX_SIZE = $clog2(MAX_CODE_SIZE);
    localparam READOUT_SIZE = MAX_CODE_SIZE + SEQUENCE_UNROLL - 1;
    input  logic [CODE_INDX_SIZE-1:0] code_size;
    input  logic [MAX_CODE_SIZE-1:0] codeword;
    input  logic [READOUT_SIZE-1:0] readout;
    output logic [CODE_INDX_SIZE-1:0] distances [SEQUENCE_UNROLL-1:0];
    
    logic [MAX_CODE_SIZE-1:0] mask;
    
    assign mask = ~({MAX_CODE_SIZE{1'b1}} << (code_size + 1));
    
    genvar i;
    generate
        for(i=0; i<SEQUENCE_UNROLL; i++) begin
            hamming_distance #(
                .WIDTH(MAX_CODE_SIZE)
                ) H_d (
                .A(mask & readout[MAX_CODE_SIZE-1+i:i]),       //
                .B(mask & codeword[MAX_CODE_SIZE-1:0]),       //
                .distance(distances[i]) // 
            );
        end
    endgenerate    
    
endmodule
