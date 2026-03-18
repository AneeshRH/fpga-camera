`timescale 1ns / 1ps

module vga_display_512(
    input            pixel_clk, // Keep 25.175 MHz (standard 640x480 clock)
    input            rst,
    input      [7:0] i_processed_pixel,
    output reg [3:0] vga_r,
    output reg [3:0] vga_g,
    output reg [3:0] vga_b,
    output reg       vga_hsync,
    output reg       vga_vsync,
    output           o_rd_en // High only when within 512x512 area
);
    // Standard VGA 640x480 @ 60Hz Timings
    localparam H_ACTIVE = 640;
    localparam H_FP     = 16;
    localparam H_SYNC   = 96;
    localparam H_BP     = 48;
    localparam H_TOTAL  = 800;

    localparam V_ACTIVE = 480; // We will extend this to accommodate 512 lines
    localparam V_FP     = 10;
    localparam V_SYNC   = 2;
    localparam V_BP     = 33;
    localparam V_TOTAL  = 525;

    // Custom Display Dimensions
    localparam DISPLAY_WIDTH  = 512;
    localparam DISPLAY_HEIGHT = 512;

    reg [9:0] h_cnt = 0;
    reg [9:0] v_cnt = 0;

    // The display area is restricted to the first 512 pixels and lines
    wire video_on = (h_cnt < DISPLAY_WIDTH) && (v_cnt < DISPLAY_HEIGHT);

    // Scan Control
    always @(posedge pixel_clk) begin
        if (rst) begin
            h_cnt <= 0;
            v_cnt <= 0;
        end else begin
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 0;
                if (v_cnt == V_TOTAL - 1) 
                    v_cnt <= 0;
                else 
                    v_cnt <= v_cnt + 1;
            end else begin
                h_cnt <= h_cnt + 1;
            end
        end
    end

    // Signal to the buffer to send pixel data
    assign o_rd_en = video_on;

    // Output Logic
    always @(posedge pixel_clk) begin
        if (rst) begin
            vga_hsync <= 1'b1;
            vga_vsync <= 1'b1;
            {vga_r, vga_g, vga_b} <= 12'h000;
        end else begin
            // Generate Syncs based on standard 640x480 timing positions
            vga_hsync <= ~(h_cnt >= (H_ACTIVE + H_FP) && h_cnt < (H_ACTIVE + H_FP + H_SYNC));
            vga_vsync <= ~(v_cnt >= (V_ACTIVE + V_FP) && v_cnt < (V_ACTIVE + V_FP + V_SYNC));
            
            // RGB Mapping (Grayscale)
            if (video_on) begin
                vga_r <= i_processed_pixel[7:4];
                vga_g <= i_processed_pixel[7:4];
                vga_b <= i_processed_pixel[7:4];
            end else begin
                {vga_r, vga_g, vga_b} <= 12'h000; // Black outside the 512x512 box
            end
        end
    end
endmodule