`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.12.2025 16:35:48
// Design Name: 
// Module Name: security_peripheral_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module security_peripheral_tb();
    
    localparam MAX_KEY_SIZE = 128;
    localparam MAX_CYCLES = 127;
    localparam METRIC_SIZE = 4;
    localparam WORDS = 4;
    localparam WIDTH = 8;
    localparam DEPTH = 256;
    localparam KEY_INDX_SIZE = $clog2(MAX_KEY_SIZE+1);
    localparam COUNT_SIZE = $clog2(MAX_CYCLES+1);
    localparam ADDRESS_SIZE = $clog2(DEPTH);
    localparam UNSTABILITY_SIZE = $clog2(MAX_KEY_SIZE) + (1<<METRIC_SIZE) - 1;
    
    logic clk, rst, start, valid, valid_reg;
    logic [WIDTH-1:0] read_data;
    logic [ADDRESS_SIZE-1:0] start_address;
    logic [KEY_INDX_SIZE-1:0] key_size;
    logic [COUNT_SIZE-1:0] cycles;
    logic [MAX_KEY_SIZE-1:0] key;
    logic [UNSTABILITY_SIZE-1:0] unstability;
    int i;
    string number;
    string file_name;
    
    always #5 clk = ~clk;
        
    always_ff @(posedge clk) begin
        if(rst) begin
            i = 0;
            valid_reg <= 1'b0;
            file_name = {"L45_", $sformatf("%0d", i), ".mem"};
            $display("reading memory L45_%0d", i);
            $readmemh(file_name, DUT.Memory.i_SRAM_1P_behavioral_bm_bist.memory);
        end
        else begin
            valid_reg <= valid;
            if(sram_on == 1'b0) begin
                if(i == cycles-1)
                    i = 0;
                else
                    i = i + 1;
                file_name = {"L45_", $sformatf("%0d", i), ".mem"};
                $display("reading memory L45_%0d", i);
                $readmemh(file_name, DUT.Memory.i_SRAM_1P_behavioral_bm_bist.memory);
            end
        end
    end
    
    initial begin
        clk = 1'b1;
        rst = 1'b0;
        start = 1'b0;
        key_size = 8'd16;
        cycles = 8'd4;
        start_address = 8'd0;
        #13
        rst = 1'b1;
        #10
        rst = 1'b0;
        #10
        start = 1'b1;
        #300
        start = 1'b0;
        #10
        start_address = 8'd4;
        cycles = 8'd15;
        key_size = 8'd32;
        #10
        start = 1'b1;
        #800
        start = 1'b0;
        #10
        start = 1'b1;
        #10
        start_address = 8'd0;
        #10
        start = 1'b0;
        #10
        start = 1'b1;      
        #1500  
        cycles = 8'd31;
        start = 1'b0;
        #10
        start = 1'b1;
    end
    
    always_ff @(posedge clk) begin
        if(valid==1'b1 && valid_reg==1'b0) begin
            $display("key: %0h,  unstability: %0h", key, unstability);
        end
    end
    
    security_peripheral #(
        .MAX_KEY_SIZE(MAX_KEY_SIZE),  // maximum size of derived key in bits
        .MAX_CYCLES(MAX_CYCLES),   // 
        .METRIC_SIZE(METRIC_SIZE),    // significant figures in bit-unstability metrics
        .WORDS(WORDS)          // number of words in the shift register
        ) DUT (
        .clock(clk),           // 1 bit input: clock signal
        .reset(rst),           // 1 bit input: reset signal
        .key_size(key_size),        // configured key size in bits
        .cycles(cycles),          // configured number of power-on cycles
        .start_address(start_address),   // clog2(WIDTH) bits output: memory address
        .start(start),           // 1 bit input: start signal
        .key(key),             // MAX_KEY_SIZE bits output: derivated key
        .unstability(unstability),     // clog2(MAX_KEY_SIZE)+(1<<METRIC_SIZE)-1 bits output: unstability metric
        .valid(valid),            // 1 bit input: key is valid
        .read_data(read_data),       // WIDTH bits input: memory data
        .sram_on(sram_on),         // 1 bit output:
        .sram_rdy(sram_rdy)         // 1 bit input:
    );   

    memory_power Power (
        .clock(clk),   // 1 bit input: clock signal
        .reset(rst),   // 1 bit input: reset signal
        .on(sram_on),      // 1 bit input: turn on memory
        .ready(sram_rdy)    // 1 bit output: memory is powered and ready to use
    );
    
endmodule
