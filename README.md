# OV7670 Real-Time Image Processing System on FPGA

A fully hardware-implemented real-time image processing pipeline on an FPGA, capturing live video from an OV7670 camera module, applying selectable convolution filters, and displaying the processed output over VGA at 640×480 resolution.

---

## Overview

This project implements a complete camera-to-display pipeline in Verilog, running entirely on FPGA fabric with no CPU or software involvement. Incoming pixel data from the OV7670 camera is processed through a 3-channel parallel convolution engine and stored in Block RAM, which is continuously read out by a VGA display controller.

---

## System Architecture

```
OV7670 Camera
     │
     ▼
 cam_top (SCCB Init + Pixel Capture)
     │  12-bit RGB444
     ▼
 imageProcessTop
 ├── Red Channel   → imageControl → conv
 ├── Green Channel → imageControl → conv
 └── Blue Channel  → imageControl → conv
     │  12-bit processed RGB444
     ▼
 mem_bram (640×480 Pixel Buffer)
     │
     ▼
 vga_top → VGA Display (640×480 @ 60Hz)
```

---

## Module Descriptions

| Module | Description |
|---|---|
| `top.v` | Top-level module. Connects all subsystems, manages clock domains and reset synchronizers |
| `cam_top.v` | Camera subsystem top. Instantiates debouncer, SCCB init, and pixel capture |
| `cam_init.v` | Sends configuration registers to OV7670 via SCCB protocol |
| `cam_capture.v` | Samples incoming pixel bytes and assembles 12-bit RGB444 pixels |
| `cam_config.v` | ROM containing OV7670 register configuration values |
| `cam_rom.v` | Stores camera register address/data pairs for initialization |
| `sccb_master.v` | SCCB (I²C-like) master for writing to OV7670 registers |
| `imageProcessTop.v` | Image processing top. Runs 3 parallel pipelines for R, G, B channels |
| `imageControl.v` | Buffers incoming pixels and assembles 3×3 pixel windows |
| `conv.v` | 3×3 convolution engine with 8 selectable kernels |
| `lineBuffer.v` | Stores pixel rows to construct 3×3 neighborhoods for convolution |
| `mem_bram.v` | Dual-port Block RAM for storing processed pixel data |
| `vga_top.v` | VGA subsystem top. Generates BRAM read addresses and routes pixel data |
| `vga_driver.v` | Generates VGA sync signals and X/Y pixel counters |
| `debounce.v` | Button debouncer for reset and camera start signals |

---

## Selectable Convolution Kernels

The `i_kernel_sel` input (3-bit) selects from 8 real-time image filters:

| `i_kernel_sel` | Filter |
|---|---|
| `000` | Identity (Pass-through) |
| `001` | Sobel Edge Detection |
| `010` | Box Blur |
| `011` | Negative |
| `100` | Sharpen |
| `101` | Emboss |
| `110` | Edge Enhance |
| `111` | Custom |

---

## IP Cores Used

| IP Core | Description |
|---|---|
| `clk_wiz_1` | Vivado Clocking Wizard — generates 25 MHz (VGA) and camera XCLK |
| `outputBuffer` | AXI4-Stream FIFO — buffers processed pixels between clock domains |

---

## Top-Level I/O

| Port | Direction | Description |
|---|---|---|
| `i_top_clk` | Input | System clock (100 MHz) |
| `i_top_rst` | Input | Active-low reset button |
| `i_kernel_sel[2:0]` | Input | Convolution kernel selector |
| `i_top_cam_start` | Input | Button to begin camera initialization |
| `o_top_cam_done` | Output | Indicates camera initialization complete |
| `i_top_pclk` | Input | OV7670 pixel clock |
| `i_top_pix_byte[7:0]` | Input | OV7670 pixel data bus |
| `i_top_pix_vsync` | Input | OV7670 vertical sync |
| `i_top_pix_href` | Input | OV7670 horizontal reference |
| `o_top_siod / o_top_sioc` | Output | SCCB data/clock lines |
| `o_top_xclk` | Output | 24 MHz clock to OV7670 |
| `o_top_vga_red/green/blue[3:0]` | Output | 12-bit RGB VGA output |
| `o_top_vga_vsync / hsync` | Output | VGA sync signals |

---

## Tools & Requirements

- **Vivado** 2020.x or later
- **Target FPGA:** Xilinx 7-Series (e.g., Basys 3 / Nexys A7)
- **Camera Module:** OV7670 (without FIFO)
- **Display:** VGA monitor (640×480 @ 60Hz)

---

## Getting Started

1. Clone the repository
2. Open Vivado and create a new project
3. Add all `.v` files from the `rtl/` folder as design sources
4. Add `.xci` files from `ip_files/` to regenerate IP cores
5. Add your board constraint file (`.xdc`)
6. Synthesize, implement, and generate bitstream
7. Program the FPGA
8. Press the **cam_start** button to initialize the OV7670
9. Use the **kernel_sel** switches to change filters in real time

---

## Project Structure

```
├── rtl/               # All Verilog source files
├── ip_files/          # Vivado IP cores (.xci)
└── README.md
```
