`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 09.12.2025
// Design Name: sram_puf
// Module Name: tmvs_tb
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tmvs_tb();

    localparam MAX_KEY_SIZE = 16;
    localparam MAX_BOOK_SIZE = 8;
    localparam MAX_CODE_SIZE = 8;
    localparam MAX_CYCLES = 32;
    localparam WORDS = 4;
    localparam KEY_INDX_SIZE = $clog2(MAX_KEY_SIZE);
    localparam BOOK_INDX_SIZE = $clog2(MAX_BOOK_SIZE);
    localparam CODE_INDX_SIZE = $clog2(MAX_CODE_SIZE);
    localparam COUNT_SIZE = $clog2(MAX_CYCLES);
    localparam SUM_SIZE = $clog2(MAX_CODE_SIZE*MAX_CYCLES+1);
    
    logic clk, rst, start, done;
    logic [KEY_INDX_SIZE-1:0] key_size;
    logic [BOOK_INDX_SIZE-1:0] book_size;
    logic [CODE_INDX_SIZE-1:0] code_size;
    logic [SUM_SIZE-1:0] th_low, th_high;
    logic [COUNT_SIZE-1:0] cycles;
    logic [MAX_CODE_SIZE-1:0] codebook [MAX_BOOK_SIZE-1:0];
    logic [MAX_CODE_SIZE-1:0] codeword;
    logic [BOOK_INDX_SIZE-1:0] code_index;
    logic [MAX_KEY_SIZE-1:0] key;
    logic on_reg;
    int i;
    string file_name;
        
    assign codeword = codebook[code_index];
    always #5 clk = ~clk;
    
    always_ff @(posedge clk) begin
        if(rst) begin
            on_reg <= 1'b0;
            i = 0;
            file_name = {"L45_", $sformatf("%0d", i), ".mem"};
            $display("reading memory L45_%0d", i);
            $readmemh(file_name, DUT.Memory.i_SRAM_1P_behavioral_bm_bist.memory);
        end
        else begin
            on_reg <= DUT.on;
            if((DUT.on == 1'b0) && (on_reg == 1'b1)) begin
                if(i == 3)
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
        key_size = 5'd15;
        book_size = 3'd3;
        code_size = 4'd6;
        th_low = 9'd4;
        th_high = 9'd24;
        cycles = 5'd3;
        codebook[0] = 7'b0000000;
        codebook[1] = 7'b0000111;
        codebook[2] = 7'b0101011;
        codebook[3] = 7'b1001010;
        #13
        rst = 1'b1;
        #10
        rst = 1'b0;
        start = 1'b1;
        #10
        start = 1'b0;
    end
    
    always_ff @(posedge clk) begin
        if(DUT.success) begin
            $display("distance: %0d for codeword: %0h at @: %0d bit: %0d", DUT.distance, DUT.codeword, DUT.checkpoint-(!DUT.Buffer.first)*DUT.OVERLAP+(DUT.index>>4), DUT.index[3:0]);
        end
    end
    
    tmvs #(
        .MAX_KEY_SIZE(MAX_KEY_SIZE),  // maximum size of derived key in bits
        .MAX_BOOK_SIZE(MAX_BOOK_SIZE), // maximum number of codewords
        .MAX_CODE_SIZE(MAX_CODE_SIZE), // maximum size of codewords in bits
        .MAX_CYCLES(MAX_CYCLES),    // maximum number of power-on cycles
        .WORDS(WORDS)           // number of words read on each powe-on cycle
        ) DUT (
        .clock(clk),
        .reset(rst),
        .start(start),       //
        .key_size(key_size),    // configured key size in bits
        .book_size(book_size),   // configured number of codewords
        .code_size(code_size),   // configured codeword size in bits
        .th_low(th_low),   // 
        .th_high(th_high),   // 
        .cycles(cycles),      // configured number of power-on cycles
        .code_index(code_index),  // clog2(MAX_BOOK_SIZE) bits output: codeword selection index
        .codeword(codeword),    // MAX_CODE_SIZE bits input: selected codeword value
        .key(key),         // MAX_KEY_SIZE bits output: derivated key
        .done(done)         // 1 bit input: key is valid
    );

endmodule
