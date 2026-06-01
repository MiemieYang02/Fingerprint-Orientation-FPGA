# FPGA Orientation Field Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Phase 1 Vivado/RTL skeleton for a 256x256 Sobel + CORDIC-wrapper + block-statistics orientation-field pipeline.

**Architecture:** Use a Verilog-2001 pixel-stream pipeline with a simulation image source, 3x3 window generator, Sobel core, CORDIC angle wrapper, 8-bin quantizer, and 16x16 block direction statistics. Keep camera, DDR3, and HDMI as reserved boundaries.

**Tech Stack:** Vivado 2025.2, XSim (`xvlog`, `xelab`, `xsim`), Verilog-2001, PowerShell, Python for later PNG conversion.

---

## File Structure

- Create `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/top/fpga_orientation_top.v`: connects the Phase 1 algorithm pipeline.
- Create `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/image/image_source_sim.v`: emits a deterministic 256x256 grayscale pixel stream.
- Create `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/image/pixel_window_3x3.v`: forms 3x3 windows from the pixel stream.
- Create `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/sobel/sobel_core.v`: computes signed Sobel `gx` and `gy`.
- Create `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/cordic/cordic_angle_ip_wrapper.v`: provides the Phase 1 angle-code boundary and leaves a clean CORDIC IP integration point.
- Create `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/direction/direction_quantizer.v`: maps angle code to 8 direction bins.
- Create `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/direction/block_direction_stat.v`: outputs one dominant 3-bit direction per 16x16 block.
- Create `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/hdmi_overlay_stub.v`: reserved final HDMI boundary.
- Create `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sim_1/new/tb_fpga_orientation_top.v`: checks that a horizontal ramp image produces direction bin 0 for every block.
- Create `scripts/run_xsim_phase1.tcl`: compiles and runs the Phase 1 simulation.
- Create `scripts/update_vivado_project.tcl`: adds sources to the existing Vivado project.
- Create `scripts/dir_map_to_png.py`: converts a direction map text file to a small PNG visualization.

## Task 1: Add the Failing Phase 1 Simulation

**Files:**
- Create: `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sim_1/new/tb_fpga_orientation_top.v`
- Create: `scripts/run_xsim_phase1.tcl`

- [ ] **Step 1: Write the failing testbench**

The testbench instantiates `fpga_orientation_top`, counts `block_valid` pulses, and fails if any `block_dir` is not `3'd0` for the built-in horizontal-ramp image.

- [ ] **Step 2: Run test to verify it fails before RTL exists**

Run:

```powershell
vivado -mode batch -source scripts/run_xsim_phase1.tcl
```

Expected: FAIL during compile/elaboration because `fpga_orientation_top` is not defined yet.

## Task 2: Implement the Pixel Pipeline

**Files:**
- Create: all RTL files listed above.

- [ ] **Step 1: Implement minimal RTL**

Implement the smallest complete pipeline that passes the horizontal-ramp test.

- [ ] **Step 2: Run Phase 1 simulation**

Run:

```powershell
vivado -mode batch -source scripts/run_xsim_phase1.tcl
```

Expected: PASS with `PHASE1_TEST_PASS blocks=256`.

## Task 3: Integrate Sources with the Existing Vivado Project

**Files:**
- Create: `scripts/update_vivado_project.tcl`
- Modify: `fingerprint_direction_fpga/fingerprint_direction_fpga.xpr` through Vivado Tcl only when the script is run.

- [ ] **Step 1: Add files to the Vivado project**

Run:

```powershell
vivado -mode batch -source scripts/update_vivado_project.tcl
```

Expected: Vivado project opens, sources are added to `sources_1`, testbench is added to `sim_1`, and `fpga_orientation_top` becomes the RTL top.

## Task 4: Add Visualization Helper

**Files:**
- Create: `scripts/dir_map_to_png.py`

- [ ] **Step 1: Implement a dependency-light PNG writer**

The script reads 256 direction-bin values from `dir_map.txt` and writes a simple PPM-compatible `.ppm` image if PNG libraries are unavailable. The first implementation may emit `.ppm` while preserving the command name.

- [ ] **Step 2: Verify script help**

Run:

```powershell
python scripts/dir_map_to_png.py --help
```

Expected: help text prints usage and exits with code 0.

## Self-Review

- Spec coverage: Phase 1 algorithm skeleton, simulation, project integration, and final HDMI/DDR3 boundaries are represented.
- Placeholders: no TBD/TODO steps are left in the plan.
- Type consistency: direction bins are consistently 3-bit values, block coordinates are 4-bit values, and Phase 1 image coordinates are 8-bit values.
