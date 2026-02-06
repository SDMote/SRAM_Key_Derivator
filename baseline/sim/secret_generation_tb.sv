`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.11.2025 17:02:10
// Design Name: 
// Module Name: secret_generation_tb
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


module secret_generation_tb();

    localparam KEY_SIZE = 16;
    localparam BOOK_SIZE = 4;
    localparam CODE_SIZE = 7;
    localparam THRESHOLD = 1;
    localparam CYCLES = 4;
    localparam SEQUENCES = 32;
    localparam KEY_INDX_SIZE = $clog2(KEY_SIZE);
    localparam BOOK_INDX_SIZE = $clog2(BOOK_SIZE);
    localparam CODE_INDX_SIZE = $clog2(CODE_SIZE);
    localparam COUNT_SIZE = $clog2(CYCLES);
    localparam SUM_SIZE = $clog2(CODE_SIZE*CYCLES+1);
    
    logic clk, rst, start, done;
    logic [CODE_SIZE-1:0] codebook [BOOK_SIZE-1:0];
    logic [CODE_SIZE-1:0] codeword;
    logic [BOOK_INDX_SIZE-1:0] code_index;
    logic [KEY_SIZE-1:0] key;
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
        if(DUT.Buffer.success) begin
            $display("distance: %0d for codeword: %0h at @: %0d bit: %0d", DUT.Buffer.Selector.current_sum, DUT.codeword, (DUT.Buffer.checkpoint+DUT.Buffer.index)>>4, DUT.Buffer.offset);
        end
    end
    
    
    secret_generation #(
        .KEY_SIZE(KEY_SIZE),  // maximum size of derived key in bits
        .BOOK_SIZE(BOOK_SIZE), // maximum number of codewords
        .CODE_SIZE(CODE_SIZE), // maximum size of codewords in bits
        .THRESHOLD(THRESHOLD),      // 
        .CYCLES(CYCLES),    // maximum number of power-on cycles
        .SEQUENCES(SEQUENCES)
        ) DUT (
        .clock(clk),
        .reset(rst),
        .start(start),       //
        .code_index(code_index),  // clog2(MAX_BOOK_SIZE) bits output: codeword selection index
        .codeword(codeword),    // MAX_CODE_SIZE bits input: selected codeword value
        .key(key),         // MAX_KEY_SIZE bits output: derivated key
        .done(done)         // 1 bit input: key is valid
    );

endmodule
