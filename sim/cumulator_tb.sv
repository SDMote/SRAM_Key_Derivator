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


module cumulator_tb();

    localparam MAX_CYCLES = 10;
    localparam WIDTH = 16;
    localparam DEPTH = 1024;
    localparam WORDS = 4;
    localparam OVERLAP = 1;
    localparam ADDRESS_SIZE = $clog2(DEPTH);
    localparam SUM_SIZE = $clog2(MAX_CYCLES+1);
    localparam REG_SIZE = WORDS * WIDTH;
    localparam REG_IDX_SIZE = $clog2(REG_SIZE);
    
    logic clk, rst, shift, load, full;
    logic [ADDRESS_SIZE-1:0] address, checkpoint;
    logic [WIDTH-1:0] read_data;
    logic [SUM_SIZE-1:0] shift_reg [REG_SIZE-1:0];
    int i;
    string file_name;
    
    always #5 clk = ~clk;
    
    initial begin
        i = 0;
        file_name = {"L45_", $sformatf("%0d", i), ".mem"};
        $display("reading memory L45_%0d", i);
        $readmemh(file_name, sram.i_SRAM_1P_behavioral_bm_bist.memory);
        i = 1;
        clk = 1'b1;
        rst = 1'b0;
        shift = 1'b0;
        load = 1'b0;
        checkpoint = 0;
        #13
        rst = 1'b1;
        #10
        rst = 1'b0;
        for(int j=0; j<4; j++) begin
            repeat(WORDS-1) begin
                #10
                load = 1'b1;
                #10
                load = 1'b0;
            end
            if(j==3) begin
                #10
                load = 1'b1;
                shift = 1'b1;
                #5
                checkpoint = address;
                #5
                shift = 1'b0;
                load = 1'b0;
            end
            else begin
                #10
                load = 1'b1;
                #10
                load = 1'b0;
                #30
                file_name = {"L45_", $sformatf("%0d", i), ".mem"};
                $display("reading memory L45_%0d", i);
                $readmemh(file_name, sram.i_SRAM_1P_behavioral_bm_bist.memory);
                i = (i==3) ? 0 : i+1;
                load = 1'b1;
                #10
                load = 1'b0;
            end
        end
        repeat(3) begin
            for(int j=0; j<4; j++) begin
                repeat(WORDS-2) begin
                    #10
                    load = 1'b1;
                    #10
                    load = 1'b0;
                end
                if(j==3) begin
                    #10
                    load = 1'b1;
                    shift = 1'b1;
                    #5
                    checkpoint = address;
                    #5
                    shift = 1'b0;
                    load = 1'b0;
                end
                else begin
                    #10
                    load = 1'b1;
                    #10
                    load = 1'b0;
                    #30
                    file_name = {"L45_", $sformatf("%0d", i), ".mem"};
                    $display("reading memory L45_%0d", i);
                    $readmemh(file_name, sram.i_SRAM_1P_behavioral_bm_bist.memory);
                    i = (i==3) ? 0 : i+1;
                    load = 1'b1;
                    #10
                    load = 1'b0;
                end
            end
        end
        #50
        checkpoint = 0;
        rst = 1'b1;
        #10
        rst = 1'b0;
        #10;
        for(int j=0; j<4; j++) begin
            load = 1'b1;
            repeat(WORDS-1) begin
                #10;
            end
            if(j==3) begin
                shift = 1'b1;
                #5
                checkpoint = address;
                #5
                shift = 1'b0;
                load = 1'b0;
            end
            else begin
                #10
                load = 1'b0;
                #30
                file_name = {"L45_", $sformatf("%0d", i), ".mem"};
                $display("reading memory L45_%0d", i);
                $readmemh(file_name, sram.i_SRAM_1P_behavioral_bm_bist.memory);
                i = (i==3) ? 0 : i+1;
                load = 1'b1;
                #10
                load = 1'b0;
            end
        end
        repeat(3) begin
            for(int j=0; j<4; j++) begin
                load = 1'b1;
                repeat(WORDS-2) begin
                    #10;
                end
                if(j==3) begin
                    shift = 1'b1;
                    #5
                    checkpoint = address;
                    #5
                    shift = 1'b0;
                    load = 1'b0;
                end
                else begin
                    #10
                    load = 1'b0;
                    #30
                    file_name = {"L45_", $sformatf("%0d", i), ".mem"};
                    $display("reading memory L45_%0d", i);
                    $readmemh(file_name, sram.i_SRAM_1P_behavioral_bm_bist.memory);
                    i = (i==3) ? 0 : i+1;
                    load = 1'b1;
                    #10
                    load = 1'b0;
                end
            end
        end
    end
    
    RM_IHPSG13_1P_1024x16_c2_bm_bist sram (
        .A_ADDR(address),
        .A_CLK(clk),
        .A_DIN('d0),
        .A_DOUT(read_data),
        .A_MEN(1'b1),
        .A_WEN(1'b0),
        .A_REN(1'b1),
        .A_BM({16{1'b1}}),
        .A_BIST_EN(1'b0),
        .A_DLY()
    );
    
    
    cumulator #(
        .MAX_CYCLES(MAX_CYCLES),// 
        .WIDTH(WIDTH),     // memory word size in bits
        .DEPTH(DEPTH),   // memory number of words
        .WORDS(WORDS),      // number of words in the shift register
        .OVERLAP(OVERLAP)     // number of words to keep from the back of the register when shifting
        ) DUT (
        .clock(clk),       // 1 bit input: clock signal
        .reset(rst),       // 1 bit input: reset signal
        .enable(1'b1),      // 1 bit input: reset signal
        .address(address),     // clog2(WIDTH) bits output: memory address
        .data(read_data),        // WIDTH bits input: memory data
        .word_index(),  // position currently updating
        .sums(shift_reg),        // WORDS*WIDTH array output: current buffer content
        .checkpoint(checkpoint),  // WIDTH bits input: address checkpoint to start loading from
        .load(load),        // 1 bit input: go to checkpoint address and fill shift register
        .shift(shift),     // 1 bit input: clear registers, update checkpoint and continue
        .full(full)         // 1 bit output: shift register is full
    );   
    
endmodule
