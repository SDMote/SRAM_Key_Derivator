`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 06.11.2025
// Design Name: sram_puf
// Module Name: buffer_tb
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module shift_register_tb();

    localparam WORDS = 4;
    localparam WIDTH = 16;
    localparam DEPTH = 32;
    localparam ADDRESS_SIZE = $clog2(DEPTH);
    localparam WORD_INDX_SIZE = $clog2(WORDS);
    localparam BITS = WORDS * WIDTH;
    
    logic clk, rst, fill, shift, full;
    logic WEN, REN;
    logic [ADDRESS_SIZE-1:0] ADDR, checkpoint;
    logic [WIDTH-1:0] memory [0:DEPTH-1];
    logic [WIDTH-1:0] DIN, DOUT;
    logic [BITS-1:0] shift_reg;
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 1'b1;
        rst = 1'b0;
        fill = 1'b0;
        shift = 1'b0;
        checkpoint = 0;
        #13
        rst = 1'b1;
        #10
        rst = 1'b0;
        #20
        fill = 1'b1;
        #10
        fill = 1'b0;
        repeat(15) begin
            #50
            shift = 1'b1;
            #10
            shift = 1'b0;
        end
        fill = 1'b1;
        #10
        fill = 1'b0;
        #40
        shift = 1'b1;
        #150
        shift = 1'b0;
        #50
        shift = 1'b1;
        checkpoint = ADDR;
        #10
        shift = 1'b0;
        repeat(12) begin
            #50
            shift = 1'b1;
            #10
            shift = 1'b0;
        end
        fill = 1'b1;
        #10
        fill = 1'b0;
        repeat(16) begin
            #50
            shift = 1'b1;
            #10
            shift = 1'b0;
        end
        
    end
    
    
    assign MEN = 1'b1;
    assign WEN = 1'b0;
    assign REN = 1'b1;
    always @(posedge clk) begin
        if(rst) begin
            $readmemh("init.mem", memory);
            DOUT <= 0;
        end
        else begin
            if(MEN==1'b1 && WEN==1'b1) begin
	            memory[ADDR] <= DIN;
	            if (REN==1'b1) begin
		    	     DOUT <= DIN;
		        end
            end
            else if(MEN==1'b1 && REN==1'b1) begin
                DOUT <= memory[ADDR];
            end
        end
    end
    
    shift_register #(
        .WIDTH(WIDTH),     // memory word size in bits
        .DEPTH(DEPTH),   // memory number of words
        .WORDS(WORDS)       // number of words in the shift register
        ) DUT (
        .clock(clk),       // 1 bit input: clock signal
        .reset(rst),       // 1 bit input: reset signal
        .address(ADDR),     // clog2(WIDTH) bits output: memory address
        .data(DOUT),        // WIDTH bits input: memory data
        .shift_reg(shift_reg),   // WORDS*WIDTH bits output: current shift register content
        .checkpoint(checkpoint),  // WIDTH bits input: address checkpoint to start loading from
        .fill(fill),        // 1 bit input: go to checkpoint address and fill shift register
        .shift(shift),       // 1 bit input: load a new word into the dhift register
        .full(full)         // 1 bit output: shift register is full
    );   
    
endmodule
