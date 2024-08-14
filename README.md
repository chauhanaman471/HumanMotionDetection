# HumanMotionDetection

## Overview

This project implements Human Motion Detection using the IPM-165 CW Radar Module and the PSoC 5 LP Creator Board. It includes various components such as KiCad PCB Layout, an ADC Sampling State Machine on PSoC Creator, and FFT and CFAR Algorithm implementation in MATLAB. The project showcases the integration and end result of these components.

This work is part of the academic curriculum for the subject: System Driven Hardware Designing Lab.

## Project Structure

### 1. SDHD_Lab1_Lab2

Contains:
- **KiCad Layout**: PCB layout files for the analog and digital circuits.
- **KiCad Schematic**: Schematics of the analog and digital circuits.
- **PCB Design**: Built on a 4-layer PCB board with the following layers:
  - Signal (Analog)
  - Vcc
  - Ground
  - Signal (Digital)

### 2. PSOC+MATLAB

Contains:
- **PSoC Code**: Source code for the ADC sampling state machine. The code handles the sampling of radar signals and transmits the data to MATLAB via UART.
- **MATLAB Code**: FFT and CFAR algorithms are implemented to process the ADC samples. The FFT is performed on the samples, and the CFAR algorithm analyzes these samples against a threshold value to detect motion.
