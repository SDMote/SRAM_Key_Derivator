`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 05.11.2025
// Design Name: sram_puf
// Module Name: key_derivator_tb
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module key_derivator_tb();
    
    localparam MAX_KEY_SIZE = 16;
    localparam MAX_BOOK_SIZE = 12;
    localparam MAX_CODE_SIZE = 12;
    localparam MAX_CYCLES = 8;
    localparam PARAM_NUMBER = MAX_BOOK_SIZE + 6;
    localparam PARAM_INDX_SIZE = $clog2(PARAM_NUMBER);
    
    logic clk, rst, start, valid;
    logic [MAX_KEY_SIZE-1:0] key;
    logic [PARAM_INDX_SIZE-1:0] index;
    logic [31:0] param;
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
            $readmemh(file_name, DUT.Control.Memory.i_SRAM_1P_behavioral_bm_bist.memory);
        end
        else begin
            on_reg <= DUT.Control.on;
            if((DUT.Control.on == 1'b0) && (on_reg == 1'b1)) begin
                if(i == 3)
                    i = 0;
                else
                    i = i + 1;
                file_name = {"L45_", $sformatf("%0d", i), ".mem"};
                $display("reading memory L45_%0d", i);
                $readmemh(file_name, DUT.Control.Memory.i_SRAM_1P_behavioral_bm_bist.memory);
            end
        end
    end
    
    //index:
    //0: key_size
    //1: book_size
    //2: code_size
    //3: th_low
    //4: th_high
    //5: cycles
    //else: codebook[index-6]
    
    initial begin
        clk = 1'b1;
        rst = 1'b0;
        start = 1'b0;
        index = 5'd0;
        param = 32'd0;
        #3
        rst = 1'b1;
        #10
        rst = 1'b0;
        #10
        param = 32'd8;  // key size
        #10
        index = 5'd1;
        param = 32'd4;  // book_size
        #10
        index = 5'd2;
        param = 32'd7;  // code_size
        #10
        index = 5'd3;
        param = 32'd4;  // th_low
        #10
        index = 5'd4;
        param = 32'd24;  // th_high
        #10
        index = 5'd5;
        param = 32'd4;  // cycles
        #10
        index = 5'd6;
        param = {25'd0 ,7'b0000000};  // code 0
        #10
        index = 5'd7;
        param = {25'd0 ,7'b0000111};  // code 1
        #10
        index = 5'd8;
        param = {25'd0 ,7'b1001010};  // code 2
        #10
        index = 5'd9;
        param = {25'd0 ,7'b0101011};  // code 3
        start = 1'b1;         
        #2500
        #10
        start = 1'b0;   
        #10
        start = 1'b1;       
        #2500
        index = 5'd0;
        param = 32'd16;  // key size
        #10
        index = 5'd1;
        param = 32'd12;  // book_size
        #10
        index = 5'd2;
        param = 32'd11;  // code_size
        #10
        index = 5'd3;
        param = 32'd8;  // th_low
        #10
        index = 5'd4;
        param = 32'd36;  // th_high
        #10
        index = 5'd5;
        param = 32'd4;  // cycles
        #10
        index = 5'd6;
        param = {21'd0 ,11'b000_0000_0000};  // code 0
        #10
        index = 5'd7;
        param = {21'd0 ,11'b000_1110_0011};  // code 1
        #10
        index = 5'd8;
        param = {21'd0 ,11'b101_1000_0101};  // code 2
        #10
        index = 5'd9;
        param = {21'd0 ,11'b110_0010_0111};  // code 3
        #10
        index = 5'd10;
        param = {21'd0 ,11'b011_0010_1001};  // code 4
        #10
        index = 5'd11;
        param = {21'd0 ,11'b110_1000_1010};  // code 5
        #10
        index = 5'd12;
        param = {21'd0 ,11'b101_0100_1011};  // code 6
        #10
        index = 5'd13;
        param = {21'd0 ,11'b100_0110_1100};  // code 7
        #10
        index = 5'd14;
        param = {21'd0 ,11'b110_0101_0001};  // code 8
        #10
        index = 5'd15;
        param = {21'd0 ,11'b101_0011_0010};  // code 9
        #10
        index = 5'd16;
        param = {21'd0 ,11'b100_1000_1001};  // code 10
        #10
        index = 5'd17;
        param = {21'd0 ,11'b000_0001_1111};  // code 11
        start = 1'b0;         
        #10
        start = 1'b1;         
        
    end
    
    always_ff @(posedge clk) begin
        if(DUT.Control.success) begin
            $display("distance: %0d for codeword: %0h at @: %0d bit: %0d", DUT.Control.distance, DUT.Control.codeword, DUT.Control.checkpoint-(!DUT.Control.Buffer.first)*DUT.Control.OVERLAP+(DUT.Control.index>>4), DUT.Control.index[3:0]);
        end
    end
    
    key_derivator #(
        .MAX_KEY_SIZE(MAX_KEY_SIZE),  // maximum size of derived key in bits
        .MAX_BOOK_SIZE(MAX_BOOK_SIZE), // maximum number of codewords
        .MAX_CODE_SIZE(MAX_CODE_SIZE), // maximum size of codewords in bits
        .MAX_CYCLES(MAX_CYCLES)     // maximum number of power-on cycles
        ) DUT (
        .clock(clk),       // 1 bit input: clock signal
        .reset(rst),       // 1 bit input: reset signal
        .index(index),       // clog2(MAX_BOOK_SIZE+6) bits input: parameter selection index
        .param(param),       // 32 bits input: parameter value
        .start(start),       // 1 bit input: start signal
        .key(key),         // MAX_KEY_SIZE bits output: derivated key
        .valid(valid)        // 1 bit input: key valid flag
    );

endmodule
