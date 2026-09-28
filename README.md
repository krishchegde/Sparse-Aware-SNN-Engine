# Sparse-Aware-SNN-Engine
# Sparse-Aware Synaptic Matrix–Vector Multiplication Engine for Spiking Neural Networks

## Overview

This project implements a hardware-based Sparse-Aware Synaptic
Matrix–Vector Multiplication Engine for Spiking Neural Networks (SNNs)
using Verilog HDL.

The design processes incoming spike vectors through a sparse synaptic
connectivity matrix represented using Compressed Sparse Row (CSR)
storage.

It integrates synaptic weight accumulation, Leaky Integrate-and-Fire
(LIF) neuron dynamics, threshold-based spike generation, and a basic
learning mechanism.

The design is simulated using Questa and synthesized using Intel
Quartus Prime Lite.

---

## Key Features

- CSR-based sparse synaptic connectivity representation
- Four output neurons
- Seven nonzero synaptic connections
- Synaptic weight accumulation
- Membrane potential integration and leak
- Threshold-based spike generation
- Neuron reset after firing
- Basic learning mechanism with weight updates
- Finite State Machine (FSM)-based control
- Verilog RTL implementation
- Functional verification using a Verilog testbench

---

## System Architecture

The engine consists of the following functional blocks:

1. **CSR Synaptic Storage**
   - Stores synaptic weights, column indices, and row pointers.
   - Represents sparse connectivity using seven nonzero entries.

2. **Input Spike Processing**
   - Accepts a four-bit input spike vector.
   - Checks whether each presynaptic neuron is active.

3. **Synaptic Accumulator**
   - Accumulates the weights associated with active input spikes.

4. **Membrane Potential Update**
   - Applies membrane leak.
   - Integrates accumulated synaptic input.

5. **Threshold Detection**
   - Compares membrane potential against a configurable threshold.
   - Generates an output spike when the threshold is reached.

6. **Learning Engine**
   - Updates synaptic weights based on input and output spike activity.

7. **FSM Controller**
   - Controls row processing, accumulation, neuron updates,
     learning, and completion.

---

## Block Diagram

text
       Input Spike Vector
               |
               v
      +-------------------+
      | CSR Synaptic      |
      | Storage           |
      +-------------------+
               |
               v
      +-------------------+
      | Spike Checking    |
      | and Weight Lookup |
      +-------------------+
               |
               v
      +-------------------+
      | Synaptic          |
      | Accumulator       |
      +-------------------+
               |
               v
      +-------------------+
      | Membrane Potential|
      | Update and Leak   |
      +-------------------+
               |
               v
      +-------------------+
      | Threshold         |
      | Detection         |
      +-------------------+
               |
               v
      +-------------------+
      | Output Spike      |
      | Generation        |
      +-------------------+
               |
               v
       Output Spike Vector



---

## Working Principle

### 1. Input Spike Reception

The engine receives a 4-bit input spike vector:

`spike_vector[3:0]`

Each bit represents the activity of an input neuron:
- `1` indicates an active spike.
- `0` indicates no spike.

### 2. Sparse Synaptic Processing

The synaptic connectivity is stored using CSR-related arrays:

- `values`: Stores synaptic weights.
- `col_index`: Stores presynaptic neuron indices.
- `row_ptr`: Defines the boundaries of each row.
- `row_of_entry`: Identifies the destination row of each connection.

The engine processes each row and checks whether the corresponding
presynaptic neuron has generated a spike.

If the input neuron is active, its associated synaptic weight
is added to the accumulator.

### 3. Membrane Potential Update

Each neuron maintains a membrane potential.

The engine applies a leak and adds the accumulated synaptic input:

`next_mem = max(membrane - LEAK, 0) + accumulator`

The default leak value is 1.

### 4. Threshold Detection

The updated membrane potential is compared against the threshold.

If:

`next_mem >= THRESHOLD`

The neuron generates an output spike, and its membrane potential
is reset to zero.

Otherwise, the updated membrane potential is stored.

The default threshold is 6.

### 5. Learning Mechanism

When `learn_en` is enabled, the engine updates synaptic weights
based on input and output spike activity.

- Coincident input and output spikes increase the corresponding weight.
- Active input spikes without an output spike decrease the weight.

The weight update step is one unit.
