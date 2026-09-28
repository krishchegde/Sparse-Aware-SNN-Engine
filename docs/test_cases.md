# Simulation Test Cases

## Overview

The Sparse-Aware SNN Engine was functionally simulated using Questa.

Five test scenarios were used to examine spike propagation,
membrane potential updates, threshold detection, neuron reset,
and learning behavior.

---

## Test Case 1: Initial Spike Propagation

**Input Spike Vector:** `0101`

**Expected Output:**
- Output Spike Vector: `1000`
- Membrane Potentials:
  - Neuron 0: 3
  - Neuron 1: 0
  - Neuron 2: 5
  - Neuron 3: 0

**Purpose:** Verify synaptic accumulation and initial spike generation.

**Result:** PASS

---

## Test Case 2: Membrane Leak

**Input Spike Vector:** `0000`

**Expected Output:**
- Output Spike Vector: `0000`
- Membrane Potentials:
  - Neuron 0: 2
  - Neuron 1: 0
  - Neuron 2: 4
  - Neuron 3: 0

**Purpose:** Verify membrane potential decay when no input spikes are active.

**Result:** PASS

---

## Test Case 3: Threshold Crossing

**Input Spike Vector:** `0101`

**Expected Output:**
- Output Spike Vector: `1100`
- Membrane Potentials:
  - Neuron 0: 4
  - Neuron 1: 0
  - Neuron 2: 0
  - Neuron 3: 0

**Purpose:** Verify threshold-based spike generation and membrane reset.

**Result:** PASS

---

## Test Case 4: Neuron Reset After Firing

**Input Spike Vector:** `0000`

**Expected Output:**
- Output Spike Vector: `0000`
- Membrane Potentials:
  - Neuron 0: 3
  - Neuron 1: 0
  - Neuron 2: 0
  - Neuron 3: 0

**Purpose:** Verify membrane potential behavior following neuron firing.

**Result:** PASS

---

## Test Case 5: Learning Enabled

**Input Spike Vector:** `0101`

**Learning Enable:** `1`

**Reported Output:**
- Output Spike Vector: `1000`
- Membrane Potentials:
  - Neuron 0: 5
  - Neuron 1: 0
  - Neuron 2: 5
  - Neuron 3: 0

**Purpose:** Exercise the learning-enabled operating mode.

**Result:** Completed

**Note:** The testbench does not explicitly check the updated synaptic weights.

---

## Summary

The first four test cases check the expected output spike vectors
and membrane potentials.

The fifth test case exercises learning-enabled operation.

The testbench reported that all tests passed.
