`timescale 1ns / 1ps

module system_top(
    input clk_100mhz,    // Board Oscillator 
    input reset_n,       // Active Low Reset 
    // VGA Pins
    output [3:0] vga_r,  [cite: 69]
    output [3:0] vga_g,  [cite: 69]
    output [3:0] vga_b,  [cite: 69]
    output vga_hsync,    [cite: 69]
    output vga_vsync     [cite: 69]
);

    // Internal Wires
    wire common_clk;     // Both Processing and VGA run at 25 MHz [cite: 70]
    wire [7:0] bram_out; [cite: 70]
    wire [7:0] processed_data; [cite: 71]
    wire processed_valid;      [cite: 71]
    wire vga_rd_en;            [cite: 71]
    reg [17:0] bram_addr;      [cite: 71]
    
    // --- NEW: Backpressure and Valid Signals ---
    wire pipeline_ready; 
    reg bram_data_valid;

    // 1. Clocking Wizard (Single Output) [cite: 72]
    clk_wiz_0 clk_gen (
        .clk_in1(clk_100mhz), [cite: 72]
        .clk_out1(common_clk) [cite: 72]
    );

    // 2. Image BRAM [cite: 73]
    image_bram img_mem (
        .clk(common_clk),    [cite: 73]
        .en(1'b1),           [cite: 73]
        .addr(bram_addr),    [cite: 73]
        .we(1'b0),           [cite: 73]
        .din(8'h0),          [cite: 73]
        .dout(bram_out)      [cite: 73]
    );

    // --- FIXED: BRAM Address Control with Backpressure ---
    always @(posedge common_clk) begin
        if (!reset_n) begin
            bram_addr <= 0;
        end else if (pipeline_ready) begin // Only increment when pipeline can accept data
            if (bram_addr < 262143) 
                bram_addr <= bram_addr + 1;
            else
                bram_addr <= 0;
        end
    end

    // --- NEW: BRAM Read Latency Compensation ---
    // BRAM takes 1 clock cycle to output data after the address changes.
    // We delay the ready signal by 1 cycle to create a synchronized valid signal.
    always @(posedge common_clk) begin
        if (!reset_n)
            bram_data_valid <= 1'b0;
        else
            bram_data_valid <= pipeline_ready;
    end

    // 3. Image Processing Top 
    imageProcessTop processing_unit (
        .axi_clk(common_clk),           [cite: 77]
        .axi_reset_n(reset_n),          [cite: 77]
        .i_data_valid(bram_data_valid), // FIXED: Now uses the synchronized valid signal
        .i_data(bram_out),              [cite: 77]
        .o_data_ready(pipeline_ready),  // FIXED: Tied to our backpressure control wire
        .o_data_valid(processed_valid), [cite: 77]
        .o_data(processed_data),        [cite: 77]
        .i_data_ready(vga_rd_en),       [cite: 78]
        .o_intr()                       [cite: 78]
    );

    // 4. VGA Display Controller 
    // FIXED: Module name corrected to vga_display_512 to match definition
    vga_display_512 display_unit (
        .pixel_clk(common_clk),             [cite: 79]
        .rst(!reset_n),                     [cite: 79]
        .i_processed_pixel(processed_data), [cite: 79]
        .vga_r(vga_r),                      [cite: 79]
        .vga_g(vga_g),                      [cite: 79]
        .vga_b(vga_b),                      [cite: 79]
        .vga_hsync(vga_hsync),              [cite: 79]
        .vga_vsync(vga_vsync),              [cite: 79]
        .o_rd_en(vga_rd_en)                 [cite: 79]
    );

endmodule