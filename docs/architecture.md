# CSR Architecture of the Sparse-Aware SNN Engine

## 1. Overview

The Sparse-Aware Synaptic Matrix–Vector Multiplication Engine
uses Compressed Sparse Row (CSR) representation to store
synaptic connectivity.

CSR stores only the existing synaptic connections instead
of allocating storage for every possible connection.

In this implementation, the synaptic connectivity is represented
using seven nonzero connections distributed across four output
neurons.

The architecture uses four arrays:

- `values`
- `col_index`
- `row_ptr`
- `row_of_entry`

These arrays allow the engine to identify synaptic weights,
presynaptic neurons, and destination neurons.

---

## 2. Synaptic Connectivity Matrix

The design contains four output neurons and four input neurons.

The synaptic connectivity matrix is:

```text
             Input Neurons
             0  1  2  3

Output 0     1  0  2  0
Output 1     0  3  0  4
Output 2     5  0  0  0
Output 3     0  6  7  0
```

Each nonzero entry represents a synaptic connection.

The matrix contains seven nonzero weights.

---

## 3. CSR Storage Arrays

### 3.1 Values Array

The `values` array stores the weights of the nonzero
synaptic connections.

```text
Index:    0  1  2  3  4  5  6
Values:   1  2  3  4  5  6  7
```

Each entry corresponds to a synaptic weight.

### 3.2 Column Index Array

The `col_index` array stores the presynaptic neuron index
associated with each weight.

```text
Index:       0  1  2  3  4  5  6
col_index:   0  2  1  3  0  1  2
```

For example:

- Entry 0 connects input neuron 0 to output neuron 0.
- Entry 1 connects input neuron 2 to output neuron 0.
- Entry 6 connects input neuron 2 to output neuron 3.

### 3.3 Row Pointer Array

The `row_ptr` array identifies the starting and ending
positions of each output neuron's connections.

```text
row_ptr = [0, 2, 4, 5, 7]
```

The connection ranges are:

| Output Neuron | Start Index | End Index (Exclusive) | Number of Connections |
|---------------|-------------|------------------------|-----------------------|
| Neuron 0 | 0 | 2 | 2 |
| Neuron 1 | 2 | 4 | 2 |
| Neuron 2 | 4 | 5 | 1 |
| Neuron 3 | 5 | 7 | 2 |

The connection range for each row is:

`row_ptr[row]` to `row_ptr[row + 1] - 1`

### 3.4 Row of Entry Array

The `row_of_entry` array identifies the destination neuron
for each synaptic connection.

```text
row_of_entry = [0, 0, 1, 1, 2, 3, 3]
```

This array maps each stored connection to its output neuron.

---

## 4. Complete CSR Representation

The following table combines all four arrays.

| Entry | Weight | Input Neuron | Output Neuron |
|-------|--------|--------------|---------------|
| 0 | 1 | 0 | 0 |
| 1 | 2 | 2 | 0 |
| 2 | 3 | 1 | 1 |
| 3 | 4 | 3 | 1 |
| 4 | 5 | 0 | 2 |
| 5 | 6 | 1 | 3 |
| 6 | 7 | 2 | 3 |

Each entry represents one directed synaptic connection.

---

## 5. Example of CSR Processing

Consider the input spike vector:

```text
spike_vector = 0101
```

Assuming bit 0 is the least significant bit, input neurons
0 and 2 are active.

The engine processes each output neuron using its CSR row.

### Output Neuron 0

Connections:

- Input neuron 0 → Weight 1
- Input neuron 2 → Weight 2

Both input neurons are active.

Therefore:

`Accumulator = 1 + 2 = 3`

### Output Neuron 1

Connections:

- Input neuron 1 → Weight 3
- Input neuron 3 → Weight 4

Both input neurons are inactive.

Therefore:

`Accumulator = 0`

### Output Neuron 2

Connection:

- Input neuron 0 → Weight 5

Input neuron 0 is active.

Therefore:

`Accumulator = 5`

### Output Neuron 3

Connections:

- Input neuron 1 → Weight 6
- Input neuron 2 → Weight 7

Only input neuron 2 is active.

Therefore:

`Accumulator = 7`

---

## 6. Accumulation Results

For the input spike vector `0101`, the synaptic accumulation
results are:

| Output Neuron | Accumulated Input |
|---------------|-------------------|
| Neuron 0 | 3 |
| Neuron 1 | 0 |
| Neuron 2 | 5 |
| Neuron 3 | 7 |

These accumulated values are used by the membrane potential
update and threshold detection stages.

---

## 7. Advantages of CSR Representation

- Stores only existing synaptic connections.
- Avoids storing zero-valued matrix entries.
- Provides a compact representation of sparse connectivity.
- Supports sequential processing of connections by row.
- Can be extended to larger sparse connectivity matrices.

---

## 8. Architecture Summary

The CSR architecture provides a structured way to represent
synaptic connectivity in the SNN engine.

The `values` array stores synaptic weights.

The `col_index` array identifies input neurons.

The `row_ptr` array defines the connection range for each
output neuron.

The `row_of_entry` array identifies the destination neuron
associated with each connection.

Together, these arrays enable the engine to process sparse
synaptic connections and calculate the accumulated input
for each output neuron.
