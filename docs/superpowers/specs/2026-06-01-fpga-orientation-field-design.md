# FPGA Image Orientation Field and Fingerprint Feature Analysis Design

## 1. Project Goal

This project implements an FPGA-based image orientation field calculation and fingerprint structure analysis system. The core algorithm extracts image gradients with a Sobel operator, calculates pixel orientation with a Xilinx CORDIC IP, performs local block direction statistics, and outputs a stable direction field for fingerprint image analysis.

The target development environment is Vivado 2025.2. The target board uses a Xilinx Artix-7 XC7A75T-2FGG484 FPGA. The final hardware demonstration will output a 640x480@60Hz HDMI signal through an HDMI capture card to OBS.

## 2. Confirmed Scope

### Phase 1: Algorithm and Project Skeleton

Phase 1 focuses on a verifiable algorithm pipeline and a Vivado project skeleton:

- Input image size: 256x256 grayscale image.
- Local block size: 16x16 pixels.
- Direction field size: 16x16 blocks.
- Direction quantization: 8 direction bins.
- HDL style: Verilog-2001.
- Clocking: single 50 MHz clock.
- Reset: active-low `rst_n`.
- CORDIC implementation: Xilinx CORDIC IP.
- Output: simulation-generated direction map text and PNG visualization.
- Vivado deliverables: project creation script, RTL sources, testbench, constraints skeleton, and IP wrapper structure.

Phase 1 does not implement OV5640 capture, DDR3/MIG, or final HDMI output. It reserves clean interfaces for those later stages.

### Final Target System

The final system extends the same algorithm core into a real-time image pipeline:

```text
OV5640 camera
→ DDR3 frame buffer
→ pixel stream reader
→ Sobel gradient core
→ Xilinx CORDIC IP angle calculation
→ 16x16 block direction statistics
→ grayscale image + direction arrow overlay
→ 640x480@60Hz HDMI output
→ capture card
→ OBS
```

DDR3 is part of the final architecture because it decouples camera capture, algorithm processing, and HDMI display timing. It is deliberately deferred from Phase 1 to keep algorithm verification independent from memory-controller and video-output debugging.

## 3. Architecture

The design uses a modular pixel-stream architecture. Algorithm modules do not depend on whether pixels come from a simulation image, OV5640, or DDR3. They consume a shared pixel stream interface.

Phase 1 pipeline:

```text
image_source_sim
→ pixel_window_3x3
→ sobel_core
→ cordic_angle_ip_wrapper
→ direction_quantizer
→ block_direction_stat
→ dir_map_writer_tb
```

Final pipeline:

```text
ov5640_capture
→ ddr3_frame_buffer
→ pixel_stream_reader
→ same algorithm core
→ hdmi_overlay_display
```

This boundary allows the input source to change without rewriting Sobel, CORDIC, quantization, or block-statistics modules.

## 4. Module Breakdown

Recommended Phase 1 source tree:

```text
rtl/
├─ top/
│  └─ fpga_orientation_top.v
├─ image/
│  ├─ image_source_sim.v
│  └─ pixel_window_3x3.v
├─ sobel/
│  └─ sobel_core.v
├─ cordic/
│  └─ cordic_angle_ip_wrapper.v
├─ direction/
│  ├─ direction_quantizer.v
│  └─ block_direction_stat.v
└─ display/
   └─ hdmi_overlay_stub.v
```

Simulation and build support:

```text
sim/
├─ tb_fpga_orientation_top.v
├─ image_256x256.mem
└─ expected/

scripts/
├─ create_project.tcl
├─ run_sim.tcl
└─ dir_map_to_png.py

constraints/
└─ hx7a75c_base.xdc

vivado/
```

### Module Responsibilities

- `image_source_sim`: emits a deterministic 256x256 grayscale pixel stream during simulation.
- `pixel_window_3x3`: builds the 3x3 neighborhood needed by the Sobel operator.
- `sobel_core`: calculates signed `Gx` and `Gy`.
- `cordic_angle_ip_wrapper`: wraps the Vivado CORDIC IP and normalizes its valid/latency behavior.
- `direction_quantizer`: converts CORDIC angle output into one of 8 direction bins.
- `block_direction_stat`: accumulates direction-bin counts in each 16x16 block and emits the dominant block direction.
- `dir_map_writer_tb`: writes the 16x16 direction-field result to text for PNG conversion.
- `hdmi_overlay_stub`: reserved final-stage display boundary.

## 5. Interfaces

The common pixel stream uses these base signals:

```verilog
input         clk;
input         rst_n;

input         in_valid;
input  [7:0]  in_gray;
input  [7:0]  in_x;           // 0..255 in Phase 1
input  [7:0]  in_y;           // 0..255 in Phase 1
input         in_frame_start;
input         in_line_start;

output        out_valid;
output [7:0]  out_x;
output [7:0]  out_y;
```

Sobel stage output:

```text
gx
gy
grad_valid
```

CORDIC stage output:

```text
angle
angle_valid
```

Quantization output:

```text
dir_bin[2:0]     // 8 direction bins, 0..7
dir_valid
```

Block-statistics output:

```text
block_x[3:0]
block_y[3:0]
block_dir[2:0]
block_valid
```

The image border is handled conservatively: the outermost pixel border does not contribute valid Sobel results. Border outputs may be invalid or zero. This keeps the Sobel window logic simple and makes simulation results easy to explain.

## 6. Direction Statistics

For a 256x256 image and 16x16 block size, the system produces a 16x16 direction field.

Each block accumulates 256 pixel-level direction-bin votes. The bin with the largest count becomes the block's dominant direction. The output is a 3-bit direction code per block.

The 8 direction bins represent orientation classes over 0 to 180 degrees. The direction field is orientation-based rather than vector-direction-based, so opposite gradient directions map to the same ridge orientation class where appropriate.

## 7. Simulation and Verification

Phase 1 verification flow:

```text
1. Generate or provide a 256x256 grayscale memory file.
2. Testbench streams pixels into the RTL pipeline.
3. RTL emits a 16x16 block direction map.
4. Testbench writes `dir_map.txt`.
5. Python converts `dir_map.txt` to `dir_map.png`.
6. A software reference result is used for comparison.
```

The first verification target is behavior simulation. The second target is synthesis of the algorithm core and project skeleton in Vivado 2025.2.

Phase 1 acceptance criteria:

- Vivado project can be created from Tcl.
- CORDIC IP wrapper is included or generated reproducibly.
- Simulation produces a 16x16 direction map.
- PNG visualization shows a plausible orientation field.
- Algorithm core can be synthesized for the Artix-7 target.
- No DDR3, camera, or HDMI success is required in Phase 1.

## 8. Final HDMI and OBS Strategy

The final video target is 640x480@60Hz HDMI through a capture card into OBS. The display shows a grayscale image with direction arrows overlaid.

HDMI integration should be debugged in this order:

```text
1. Output color bars or a fixed test pattern.
2. Output a static direction-field visualization.
3. Output Phase 1 algorithm results.
4. Connect OV5640 + DDR3 real-time frame buffering.
5. Overlay real-time direction arrows on the grayscale image.
```

This order isolates HDMI/OBS compatibility from algorithm, DDR3, and camera problems.

## 9. Deferred Work

The following items are intentionally deferred until after Phase 1:

- OV5640 SCCB/I2C configuration and pixel capture.
- DDR3 MIG integration and frame-buffer arbitration.
- Pixel-stream reader from DDR3.
- HDMI timing generator, overlay renderer, and TMDS output.
- Real-time grayscale image plus direction-arrow overlay.

The Phase 1 design keeps module interfaces compatible with these later additions.
