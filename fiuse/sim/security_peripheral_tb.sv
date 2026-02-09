`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Alfonso Cortés
// 
// Create Date: 05.11.2025
// Design Name: sram_puf
// Module Name: security_peripheral_tb
// Project Name: riscv
// Description: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module security_peripheral_tb();
    
    localparam KEY_SIZE = 16;
    localparam BOOK_SIZE = 4;
    localparam CODE_SIZE = 7;
    localparam THRESHOLD = 1;
    localparam CYCLES = 4;
    localparam WORDS = 4;
    
    logic clk, rst;
    logic [KEY_SIZE-1:0] key;
    logic on_reg;
    int i;
    string file_name;
    
    always #5 clk = ~clk;
        
    always_ff @(posedge clk) begin
        if(rst) begin
            on_reg <= 1'b0;
            key <= 0;
            i = 0;
            file_name = {"L45_", $sformatf("%0d", i), ".mem"};
            $display("reading memory L45_%0d", i);
            $readmemh(file_name, DUT.Extractor.Memory.i_SRAM_1P_behavioral_bm_bist.memory);
        end
        else begin
            on_reg <= DUT.Extractor.on;
            key <= DUT.key;
            if((DUT.Extractor.on == 1'b0) && (on_reg == 1'b1)) begin
                if(i == 3)
                    i = 0;
                else
                    i = i + 1;
                file_name = {"L45_", $sformatf("%0d", i), ".mem"};
                $display("reading memory L45_%0d", i);
                $readmemh(file_name, DUT.Extractor.Memory.i_SRAM_1P_behavioral_bm_bist.memory);
            end
        end
    end
       
    initial begin
        clk = 1'b1;
        rst = 1'b0;
        #3
        rst = 1'b1;
        #10
        rst = 1'b0;
    end
    
    always_ff @(posedge clk) begin
        if(DUT.Extractor.success) begin
            $display("distance: %0d for codeword: %0h at @: %0d bit: %0d", DUT.Extractor.distance, DUT.Extractor.codeword, DUT.Extractor.checkpoint-(!DUT.Extractor.Buffer.first)*DUT.Extractor.OVERLAP+(DUT.Extractor.index>>4), DUT.Extractor.index[3:0]);
        end
    end
    
    security_peripheral #(
        .KEY_SIZE(KEY_SIZE),  // maximum size of derived key in bits
        .THRESHOLD(THRESHOLD),  // 
        .CYCLES(CYCLES),    // maximum number of power-on cycles
        .WORDS(WORDS)           // number of words read on each powe-on cycle
        ) DUT (
        .clock(clk),       // 1 bit input: clock signal
        .reset(rst)        // 1 bit input: reset signal
    );

endmodule
