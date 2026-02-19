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
    logic [1:0] counter;
    enum logic [0:0] {ON, OFF} state;
    
    always_ff @(posedge clock) begin
        if (reset) begin
            state <= ON;
            counter <= 0;
            on_reg <= 1'b0;
        end
        else begin
            on_reg <= on;
            case(state)
                ON: begin
                    if((on == 1'b0) && (on_reg == 1'b1)) begin
                        state <= OFF;
                        counter <= 1;
                    end
                end
                OFF: begin
                    counter <= counter + 1;
                    if(counter == 0)
                        state <= ON;
                end
            endcase
        end        
    end
    
    always_comb begin
        case(state)
            ON: begin
                ready = 1'b1;
                if((on == 1'b0) && (on_reg == 1'b1)) begin
                    ready = 1'b0;
                end
            end
            OFF: begin
                ready = 1'b0;
            end
        endcase
    end
    
endmodule
