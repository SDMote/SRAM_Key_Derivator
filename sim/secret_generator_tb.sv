`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 02.12.2025
// Design Name: sram_puf
// Module Name: secret_generator_tb
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module secret_generator_tb();
    
    localparam MAX_KEY_SIZE = 128;
    localparam MAX_CYCLES = 127;
    localparam METRIC_SIZE = 3;
    localparam WIDTH = 8;
    localparam DEPTH = 256;
    localparam WORDS = 2;
    localparam KEY_INDX_SIZE = $clog2(MAX_KEY_SIZE+1);
    localparam COUNT_SIZE = $clog2(MAX_CYCLES+1);
    localparam ADDRESS_SIZE = $clog2(DEPTH);
    localparam UNSTABILITY_SIZE = $clog2(MAX_KEY_SIZE) + (1<<METRIC_SIZE) - 1;
    
    logic clk, rst, enable, sram_on, sram_rdy, done;
    logic [ADDRESS_SIZE-1:0] address;
    logic [WIDTH-1:0] read_data;
    logic [ADDRESS_SIZE-1:0] start_address;
    logic [KEY_INDX_SIZE-1:0] key_size;
    logic [COUNT_SIZE-1:0] cycles;
    logic [MAX_KEY_SIZE-1:0] key;
    logic [UNSTABILITY_SIZE-1:0] unstability;
    logic on_reg;
    int i;
    string file_name;
    
    always #5 clk = ~clk;
    
    always_ff @(posedge clk) begin
        if(rst) begin
            on_reg <= 1'b0;
            i = 0;
            file_name = {"L45_", $sformatf("%0d", i), ".mem"};
            $display("reading memory L45_%0d", i);
            $readmemh(file_name, Memory.i_SRAM_1P_behavioral_bm_bist.memory);
        end
        else begin
            on_reg <= sram_on;
            if((sram_on == 1'b0) && (on_reg == 1'b1)) begin
                if(i == cycles-1)
                    i = 0;
                else
                    i = i + 1;
                file_name = {"L45_", $sformatf("%0d", i), ".mem"};
                $display("reading memory L45_%0d", i);
                $readmemh(file_name, Memory.i_SRAM_1P_behavioral_bm_bist.memory);
            end
        end
    end
    
    initial begin
        clk = 1'b1;
        rst = 1'b0;
        enable = 1'b0;
        start_address = 8'h0;
        key_size = 5'd16;
        cycles = 8'd4;
        #13
        rst = 1'b1;
        #10
        rst = 1'b0;
        enable = 1'b1;
        #300
        start_address = 8'h4;
        key_size = 32;
        cycles = 15;
        #10
        enable = 1'b0;
        #10
        enable = 1'b1;        
    end
    
    secret_generator #(
        .MAX_KEY_SIZE(MAX_KEY_SIZE),  // maximum size of derived key in bits
        .MAX_CYCLES(MAX_CYCLES),   // 
        .METRIC_SIZE(METRIC_SIZE),    // significant figures in bit-unstability metrics
        .WIDTH(WIDTH),          // memory word size in bits
        .DEPTH(DEPTH),        // memory number of words
        .WORDS(WORDS)          // number of words in the shift register
        ) DUT (
        .clock(clk),           // 1 bit input: clock signal
        .reset(rst),           // 1 bit input: reset signal
        .enable(enable),          // 1 bit input: start signal
        .address(address),         // clog2(WIDTH) bits output: memory address
        .data(read_data),            // WIDTH bits input: memory data
        .start_address(start_address),   // clog2(WIDTH) bits input: start memory address
        .key_size(key_size),        // configured key size in bits
        .cycles(cycles),          // configured number of power-on cycles
        .sram_on(sram_on),         // 1 bit output:
        .sram_rdy(sram_rdy),        // 1 bit input:
        .key(key),             // MAX_KEY_SIZE bits output: derivated key
        .unstability(unstability),     // clog2(MAX_KEY_SIZE) + clog2(MAX_CYCLES/2) bits output: unstability metric
        .done(done)             // 1 bit input: key is valid
    );   

    RM_IHPSG13_1P_256x8_c3_bm_bist Memory (
        .A_ADDR(address),
        .A_CLK(clk),
        .A_DIN(8'd0),
        .A_DOUT(read_data),
        .A_MEN(sram_on),
        .A_WEN(1'b0),
        .A_REN(1'b1),
        .A_BM({8{1'b1}}),
        .A_DLY(1'b1),       //  must always be 1
        .A_BIST_EN(1'b0),   // disable BIST
        .A_BIST_CLK(1'b0),
        .A_BIST_MEN(1'b0),
        .A_BIST_WEN(1'b0),
        .A_BIST_REN(1'b0),
        .A_BIST_ADDR({8{1'b0}}),
        .A_BIST_DIN({8{1'b0}}),
        .A_BIST_BM({8{1'b0}})
    );
    
    memory_power Power (
        .clock(clk),   // 1 bit input: clock signal
        .reset(rst),   // 1 bit input: reset signal
        .on(sram_on),      // 1 bit input: turn on memory
        .ready(sram_rdy)    // 1 bit output: memory is powered and ready to use
    );
    
endmodule
