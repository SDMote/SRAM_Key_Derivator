`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 05.11.2025
// Design Name: sram_puf
// Module Name: hamming_distance
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


///////////////////////////// Instantiation Template /////////////////////////////
//    hamming_distance #(
//        .WIDTH(8)
//        ) instance_name (
//        .A(),       //
//        .B(),       //
//        .distance() // 
//    );
//////////////////////////////////////////////////////////////////////////////////


module hamming_distance #(WIDTH=8)(
    A,
    B,
    distance
    );
    
    localparam SIZE = $clog2(WIDTH);
    input  logic [WIDTH-1:0] A; 
    input  logic [WIDTH-1:0] B;
    output logic [SIZE-1:0] distance;
    
    logic [WIDTH-1:0] C;
    assign C = A^B;
    
    always_comb begin
        distance = 0;
        for (int i = 0; i < WIDTH; i++) begin
            distance = distance + C[i];
        end
    end
    
endmodule

