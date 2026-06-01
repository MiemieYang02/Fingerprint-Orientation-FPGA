# HDMI Static Display Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a board-level HDMI static display top so the project can output a 640x480 test/direction-field pattern to the capture card before integrating OV5640 and DDR3.

**Architecture:** Keep the verified Phase 1 algorithm top unchanged. Add a separate HDMI top that generates pixel/serial clocks from the 50 MHz board clock, produces 640x480 timing, renders a static direction-field-style pattern, TMDS-encodes RGB, and drives HDMI-A pins using the same pin naming style as the reference OV5640 HDMI project.

**Tech Stack:** Vivado 2025.2, Verilog-2001, Artix-7 primitives (`MMCME2_BASE`, `BUFG`, `OSERDESE2`, `OBUFDS`), PowerShell, XSim/Vivado batch scripts.

---

## File Structure

- Create `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/hdmi_clock_gen.v`: derive 25 MHz pixel clock and 125 MHz serial clock from `sys_clk`.
- Create `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/video_timing_640x480.v`: generate VGA-compatible 640x480 timing signals.
- Create `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/hdmi_static_pattern.v`: generate color bars and a 16x16 direction-field preview.
- Create `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/tmds_encoder.v`: encode one 8-bit channel to a 10-bit TMDS symbol.
- Create `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/tmds_serializer_10to1.v`: serialize a TMDS symbol using OSERDESE2.
- Create `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/hdmi_tx_640x480.v`: connect timing, encoders, serializers, and differential buffers.
- Create `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/top/fingerprint_hdmi_static_top.v`: board-level top for HDMI static output.
- Modify `fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/constrs_1/new/phase1_base.xdc`: guard constraints for both Phase 1 and HDMI tops and enable HDMI pins.
- Modify `scripts/update_vivado_project.tcl`: add Phase 2 HDMI files without removing Phase 1 files.
- Create `scripts/run_synth_hdmi_static.tcl`: synthesize `fingerprint_hdmi_static_top`.

## Task 1: Add HDMI Display RTL

- [ ] **Step 1:** Implement clock generation, timing, static pattern, TMDS encoder, serializer, HDMI TX, and board top.
- [ ] **Step 2:** Keep Phase 1 top untouched so prior simulation remains valid.

## Task 2: Integrate with Vivado Project

- [ ] **Step 1:** Update the project script to add all HDMI files.
- [ ] **Step 2:** Update XDC constraints so both `clk/rst_n` and `sys_clk/sys_rst_n` top names are supported.
- [ ] **Step 3:** Add HDMI-A pins from the reference OV5640 HDMI-A project.

## Task 3: Verify

- [ ] **Step 1:** Re-run Phase 1 simulation and confirm `PHASE1_TEST_PASS blocks=256`.
- [ ] **Step 2:** Run `vivado -mode batch -source scripts/update_vivado_project.tcl`.
- [ ] **Step 3:** Run `vivado -mode batch -source scripts/run_synth_hdmi_static.tcl` and confirm synthesis completes.

## Self-Review

- Phase 1 algorithm top remains available.
- Phase 2 HDMI top is independent and can be selected as the Vivado top for bitstream generation.
- DDR3 and OV5640 remain intentionally out of scope for this phase.
