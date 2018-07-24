# HDC Library for On-Chip Learning and Classification
This repository provides a framework draft for an HDC classifier implementation in VHDL. The RTL model is fully synthesizable.

## Getting Started
Included are:
- configurable VHDL library modules for HDC learning and classification
- MATLAB scripts to configure the VHDL modules  

### Prerequisities
To use this framework, the following software is required
- MATLAB 2017b

For the VHDL modules, the VHDL-2008 standard was followed. Other tools which the modules might be used with may have to be adapted to the standard.

### Folder Structure
```
.
├── matlab
│   ├── file_io
│   │   └── ...                        # Scripts for module configuration
│   ├── hdc
│   │   └── ...                        # HD computing functions
│   └── initParameters.m               # Script for initialization of memories, etc.
└── vhdl
    ├── source
    │   ├── associative_memory
    │   │   └── ...                    # Associative memory modules
    │   ├── spatial_encoder
    │   │   └── ...                    # Spatial encoder modules
    │   ├── support_circuits
    │   │   └── ...                    # Submodules
    │   ├── temporal_encoder
    │   │   └── ...                    # Temporal encoder modules
    │	└── ...                        # Packages and top level modules
    └── templates
        └── ...                        # Templates used by MATLAB for configuration
```

## User Guide
### Configuration
The classifier architecture can be configured according to ones needs. This has to be done in the MATLAB scripts, since configuring the architecture requires to initialise multiple hypervectors and hypervector arrays, totalling several thousand bits, which can be automatically generated. To do so, follow these steps:

**1.** Open MATLAB and navigate to the folder [matlab](./matlab/), execute `addpath(genpath('.'))` in the command window to make all functions and scripts accessible.

---

**2.** Adjust the parameters and modes in the MATLAB file [initParameters](./matlab/initParameters.m).

Following parameters have to be set to fully determine the classifier:
```matlab
HV_DIMENSION
CLASSES
INPUT_CHANNELS
INPUT_QUANTIZATION
BUNDLE_CHANNEL_BITS
NGRAM_SIZE
BUNDLE_NGRAM_BITS
BUNDLE_NGRAM_CYCLES
```

---

**3.** Make the changes effective by executing the following commands.
```matlab
initParameters;
writeDataVHDL;
```
The latter script writes all parameters, lookup tables, connectivity matrices, seed vectors, etc. to VHDL packages, which are part of the architectures. It uses the files in the [templates](./vhdl/templates/) folder and overwrites the values. The packages in the [source](./vhdl/source/) folder are overwritten every time `writeDataVHDL` is called.

## Paper

M. Schmuck, L. Benini, A. Rahimi, "Hardware Optimizations of Dense Binary Hyperdimensional Computing: Rematerialization of Hypervectors, Binarized Bundling, and Combinational Associative Memory". arXiv preprint: [arXiv:1807.08583](https://arxiv.org/abs/1807.08583).
