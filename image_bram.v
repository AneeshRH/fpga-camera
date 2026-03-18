`timescale 1ns / 1ps

module image_bram(
    input          clk,
    input          rst,
    input          en,
    input  [17:0]  addr, 
    input  [7:0]   din,
    input          we,
    output reg [7:0] dout
);

    // Memory array: 512x512 = 262,144 locations
    (* ram_style = "block" *) reg [7:0] mem [262143:0];

    // Load image data at startup
    initial begin
        // Ensure "image_data.hex" is added to your Vivado project sources
        $readmemh("image_data.hex", mem);
    end

always @(posedge clk) begin
    if (en) begin
        if (we) begin
            mem[addr] <= din; // Remove citation tags here
        end
        dout <= mem[addr];    // Remove citation tags here
    end
end

endmodule