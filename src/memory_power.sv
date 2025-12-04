`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 18.11.2025
// Design Name: sram_puf
// Module Name: memory_power
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

///////////////////////////// Instantiation Template /////////////////////////////
//    memory_power instance_name (
//        .clock(),   // 1 bit input: clock signal
//        .reset(),   // 1 bit input: reset signal
//        .on(),      // 1 bit input: turn on memory
//        .ready()    // 1 bit output: memory is powered and ready to use
//    );
//////////////////////////////////////////////////////////////////////////////////

module memory_power(
    input  logic clock,
    input  logic reset,
    input  logic on,
    output logic ready
    );
    
    logic on_reg;
    
    always_ff @(posedge clock) begin
        if (reset) begin
            ready <= 0;
            on_reg <= 0;
        end
        else begin
            on_reg <= on;
            ready <= on_reg;
        end        
    end
    
endmodule
