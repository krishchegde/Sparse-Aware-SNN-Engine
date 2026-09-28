# Working Principle of the Sparse-Aware SNN Engine

## 1. Introduction

The Sparse-Aware Synaptic Matrix–Vector Multiplication Engine
is a hardware implementation of a simplified Spiking Neural
Network (SNN).

The design processes input spike vectors using a sparse synaptic
connectivity matrix stored in Compressed Sparse Row (CSR) format.

The engine performs:

1. Input spike reception
2. CSR-based synaptic connection processing
3. Synaptic weight accumulation
4. Membrane potential update
5. Threshold detection
6. Output spike generation
7. Optional synaptic weight learning

The entire process is controlled by a finite state machine (FSM).

---

## 2. Input Spike Reception

The engine receives a four-bit input spike vector:

`spike_vector[3:0]`

Each bit represents the activity of an input neuron.

- `1` indicates an active spike.
- `0` indicates no spike.

For example:

```text
spike_vector = 0101
```

Assuming bit 0 is the least significant bit, input neurons
0 and 2 are active.

The `start` signal initiates processing.

---

## 3. CSR-Based Synaptic Processing

The engine uses four arrays to represent synaptic connectivity:

| Array | Function |
|-------|----------|
| `values` | Stores synaptic weights |
| `col_index` | Stores presynaptic neuron indices |
| `row_ptr` | Defines row boundaries |
| `row_of_entry` | Identifies destination neurons |

The engine processes the synaptic connections associated
with each output neuron.

For every connection, it checks whether the corresponding
input neuron has generated a spike.

If the input neuron is active, the associated synaptic
weight contributes to the accumulator.

---

## 4. Synaptic Weight Accumulation

The accumulator collects the weights of active input
connections for each output neuron.

For the input spike vector `0101`, the active input neurons
are 0 and 2.

The accumulated synaptic inputs are:

| Output Neuron | Active Connections | Accumulated Input |
|---------------|--------------------|-------------------|
| Neuron 0 | Weights 1 and 2 | 3 |
| Neuron 1 | None | 0 |
| Neuron 2 | Weight 5 | 5 |
| Neuron 3 | Weight 7 | 7 |

These accumulated values are passed to the membrane
potential update stage.

---

## 5. Membrane Potential Update

Each output neuron maintains a membrane potential.

The engine applies a leak and adds the accumulated
synaptic input.

The update follows the implemented logic:

`next_mem = max(membrane - LEAK, 0) + accumulator`

The default leak value is 1.

This allows membrane potential to decrease when the
neuron receives no active synaptic input.

---

## 6. Threshold Detection

The updated membrane potential is compared against
the configured threshold.

The default threshold is:

`THRESHOLD = 6`

If the membrane potential reaches or exceeds the threshold,
the neuron generates an output spike.

The neuron membrane potential is then reset to zero.

Otherwise, the updated membrane potential is retained.

---

## 7. Output Spike Generation

The output spike vector contains the firing state
of the four output neurons.

Each bit corresponds to one output neuron.

- `1` indicates that the neuron generated a spike.
- `0` indicates that the neuron did not generate a spike.

For example, an output vector of `1000` indicates
that output neuron 3 fired, assuming neuron 3 is
represented by the most significant bit.

---

## 8. Learning Mechanism

The engine includes a basic learning mechanism controlled
by the `learn_en` signal.

When learning is enabled, synaptic weights are updated
based on input and output spike activity.

The implemented update behavior is:

- Increase the weight when the corresponding input and
  output neurons are both active.
- Decrease the weight when the input neuron is active
  but the output neuron does not fire.

The update step is one unit.

The design also includes weight saturation to prevent
the signed 16-bit weights from exceeding their representable
limits.

---

## 9. FSM-Based Control

The engine uses a finite state machine to control
the processing sequence.

The states are:

| State | Function |
|-------|----------|
| `IDLE` | Waits for a start request |
| `LOAD_ROW` | Loads the current row information |
| `CHECK` | Checks the current synaptic connection |
| `ACCUM` | Accumulates active synaptic weights |
| `ADVANCE` | Advances through the connections |
| `STORE` | Stores the updated neuron state |
| `NEXT_ROW` | Moves to the next output neuron |
| `UPDATE` | Performs learning updates when enabled |
| `FINISH` | Completes the processing operation |

The FSM coordinates synaptic processing, membrane
potential updates, and learning.

---

## 10. Processing Sequence

The overall processing sequence is:

```text
       Start Signal
            |
            v
    Input Spike Reception
            |
            v
    CSR Connection Lookup
            |
            v
    Synaptic Accumulation
            |
            v
    Membrane Potential Update
            |
            v
    Threshold Comparison
            |
            v
    Output Spike Generation
            |
            v
    Optional Learning Update
            |
            v
       Done Signal
```

---

## 11. Completion Signals

The engine provides two important status signals:

### `busy`

Indicates that the FSM is processing an operation.

### `done`

Indicates completion of the processing operation.

The engine returns to the idle state after completing
the operation.

---

## 12. Summary

The Sparse-Aware SNN Engine processes input spikes through
a sparse synaptic connectivity representation.

It accumulates active synaptic weights, updates membrane
potentials, compares them against a threshold, and generates
output spikes.

An optional learning mechanism modifies synaptic weights
based on input and output spike activity.

The FSM coordinates the complete processing sequence.
