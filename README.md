# Input-Filter-Design-for-buck-converter-for-conduction-EMI
Design and damping of an LC input filter for a synchronous buck converter to meet conducted‑EMI limits without destabilizing the control loop.

# Buck Converter Input Filter Damping

MATLAB scripts to design and damp an LC input filter for a synchronous buck converter, eliminating conducted‑EMI issues without destabilizing the control loop.

## Problem Statement

Adding an LC input filter to a buck converter helps attenuate conducted electromagnetic interference (EMI) at the switching frequency. However, the filter introduces a resonant peak in its output impedance `Zo`. When this peak approaches the converter's closed‑loop input impedance `ZD`, the control‑to‑output transfer function `Gvd` develops a sharp dip or notch—often near the filter resonance frequency (e.g., 19 kHz). This interaction can destabilize the converter or degrade its transient response.

The code in this repository calculates the relevant impedances, applies the Extra Element Theorem (EET) to predict the modified `Gvd`, and demonstrates a practical damping method to eliminate the notch.

## Solution Approach

A parallel `Rf`‑`Cb` damping network is added across the filter capacitor `Cf`. Proper selection of `Rf` and `Cb` flattens the `Zo` peak and keeps it well below `ZD`, satisfying the Middlebrook stability criterion:

- Choose damping resistor near the filter characteristic impedance:  
  `Rf ≈ sqrt(Lf / Cf)`
- Choose damping capacitor several times larger than `Cf`:  
  `Cb ≥ 4 · Cf`

This reduces the impedance peak by 20 dB or more and removes the `Gvd` dip.

## Repository Contents

| File | Description |
|------|-------------|
| `main_script.m` | Main MATLAB script that performs the analysis and generates Bode plots. |
| `README.md` | This file. |
| `LICENSE` | License information (MIT). |

## Requirements

- MATLAB R2020a or later
- Control System Toolbox

## Usage

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/buck-converter-input-filter-damping.git
