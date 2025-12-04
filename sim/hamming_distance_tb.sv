`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 05.11.2025
// Design Name: sram_puf
// Module Name: hamming_distance_tb
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module hamming_distance_tb();
    
    logic clk;
    logic [7:0] A, B;
    logic [2:0] d;
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 1'b1;
        A = 8'b10110010;
        B = 8'b01111010;
        #10
        A = 8'b00110010;
        #10
        A = 8'b10110111;
    end

    hamming_distance #(
        .WIDTH(8)
        ) DUT (
        .A(A),       //
        .B(B),       //
        .distance(d) // 
    );

endmodule
