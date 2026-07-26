```
SYNCHRONOUS FIFO DESIGN & VERIFICATION
│
├── RTL
│   └── Parameterized Synchronous FIFO
│
├── Directed Verification
│   ├── Basic Write/Read
│   ├── Full
│   ├── Empty
│   └── Concurrent Read/Write
│
├── Self-checking
│   └── Scoreboard / Reference Queue
│
├── Random Testing
│   ├── random data
│   ├── random write
│   └── random read
│
├── Assertions
│   ├── overflow protection
│   ├── underflow protection
│   └── pointer/state behavior
│
└── Corner Cases
    ├── Full boundary
    ├── Empty boundary
    ├── Pointer wrap-around
    ├── Simultaneous read/write
    └── Reset during operation
```
# Synchronous FIFO Design & Verification

A small SystemVerilog project focused on **verification fundamentals** rather than increasing RTL complexity unnecessarily.

The project starts from a working synchronous FIFO and evolves it into a cleaner, reusable design with a **self-checking verification environment** using a scoreboard, randomized stimulus, assertions, and corner-case testing.

## Project Goal

The main objective is to practice the transition from:

> "I can write RTL and inspect waveforms"

into:

> "I can automatically verify that an RTL design behaves correctly across normal and corner-case scenarios."

The verification side is the main focus of this project.

## Current Status

### RTL

The current FIFO implementation is a synchronous **16-entry × 8-bit** FIFO with:

- synchronous write and read operations
- asynchronous active-low reset (`rst_n`)
- write pointer and read pointer
- `full` and `empty` status flags
- write blocking when the FIFO is full
- read blocking when the FIFO is empty
- simultaneous read and write capability

### Existing Testbench

The current directed testbench already exercises:

- reset behavior
- normal write operation
- filling the FIFO until `full`
- normal read operation
- reading until `empty`
- simultaneous read and write
- asynchronous reset during operation

At this stage, most checking is still performed using `$display`, internal DUT observation, and waveform inspection. The next step is to make the testbench **self-checking**.

## Planned RTL Refactor

The RTL will only be improved enough to make it cleaner and reusable.

Planned changes:

- add `DATA_WIDTH` parameter
- add `DEPTH` parameter
- derive pointer/address widths using `$clog2`
- remove hard-coded memory and pointer sizes
- optionally define accepted operations such as:
  - `wr_fire = wr_en && !full`
  - `rd_fire = rd_en && !empty`

The purpose of this refactor is **clarity and reusability**, not to make the FIFO architecture unnecessarily complicated.

## Verification Plan

### 1. Directed Tests

Keep and clean up the existing directed tests for predictable scenarios:

- reset
- basic write/read
- FIFO fill
- FIFO drain
- full condition
- empty condition
- simultaneous read/write

### 2. Self-Checking Scoreboard

Create a reference FIFO model using a SystemVerilog queue.

The scoreboard will:

- push expected data when a write is accepted
- pop expected data when a read is accepted
- compare expected data with DUT `dout`
- count mismatches automatically
- report PASS/FAIL without relying only on waveform inspection

Primary goal: verify **FIFO ordering and data integrity**.

### 3. Random Testing

Generate randomized traffic for multiple cycles:

- random `wr_en`
- random `rd_en`
- random `din`

The scoreboard must continuously track accepted reads and writes and automatically check DUT output.

The test should be able to run hundreds or thousands of cycles without manual inspection.

### 4. Assertions

Add SystemVerilog assertions for important behavioral rules, such as:

- reset results in `empty == 1`
- reset results in `full == 0`
- read pointer does not advance on an illegal read from an empty FIFO
- write pointer does not advance on an illegal write to a full FIFO
- `full` and `empty` are not asserted simultaneously under normal operation

Assertions are intended to verify **control behavior and protocol rules**, while the scoreboard verifies **data correctness**.

### 5. Corner Cases

The following boundary conditions must be tested explicitly:

- write when empty
- read when one item remains
- transition from one item to empty
- transition from `DEPTH - 1` items to full
- write while full
- read while empty
- pointer wrap-around
- simultaneous read/write during normal occupancy
- simultaneous read/write when near empty
- simultaneous read/write when near full
- simultaneous read/write while full
- reset while FIFO contains data
- reset during simultaneous traffic

Behavior at ambiguous boundaries must be defined by the project specification before testing.

Example: if `full == 1` and both `wr_en` and `rd_en` are asserted, this implementation may reject the write and accept the read. The verification environment should test the behavior defined by the RTL specification rather than assume a different FIFO policy.

## Project Scope

This project intentionally focuses on a **single-clock synchronous FIFO** and fundamental SystemVerilog verification techniques.

### In Scope

- synchronous FIFO RTL
- parameterized RTL
- directed testbench
- reusable testbench tasks
- self-checking scoreboard
- SystemVerilog queue as reference model
- randomized stimulus
- basic/concurrent assertions
- corner-case verification
- waveform analysis for debugging
- clean simulation output and PASS/FAIL reporting

### Out of Scope

The following topics are intentionally excluded from this project:

- asynchronous FIFO
- multiple clock domains
- clock-domain crossing (CDC)
- Gray-code pointer synchronization
- metastability analysis
- AXI / AXI-Stream FIFO
- APB integration
- First-Word Fall-Through FIFO
- UVM
- formal verification
- FPGA-specific memory inference optimization
- advanced coverage-driven verification

These can be explored in later projects after the verification fundamentals in this project are solid.

## Learning Rules

1. Write the first implementation independently before asking AI to generate code.
2. Use AI mainly for review, explanation, and debugging after making a real attempt.
3. Any AI-proposed fix must be understood before being integrated.
4. Prefer a simple design with strong verification over a complex design with a weak testbench.
5. Every discovered bug should be documented with its cause and fix.
6. Waveforms are used for debugging, but final correctness should be checked automatically whenever possible.

## Suggested Repository Structure

```text
synchronous-fifo-verification/
├── rtl/
│   └── sync_fifo.sv
├── tb/
│   ├── sync_fifo_tb.sv
│   ├── fifo_scoreboard.sv      # optional separate component
│   └── fifo_assertions.sv      # optional separate component
├── sim/
│   └── run.do
├── docs/
│   ├── waveform_images/
│   └── debug_notes.md
└── README.md
```

The scoreboard and assertions may initially remain inside `sync_fifo_tb.sv` and be separated later if the testbench becomes too large.

## Definition of Done

The project is considered complete when:

- the FIFO RTL is parameterized and readable
- existing directed tests pass
- the scoreboard automatically checks FIFO ordering
- randomized read/write traffic runs without mismatches
- key behavioral assertions are implemented
- all listed corner cases have been intentionally tested
- pointer wrap-around is verified
- reset behavior during active traffic is verified
- simulation produces a clear final PASS/FAIL summary
- the README and selected waveform screenshots clearly explain the design and verification approach

## Recommended Development Order

```text
Clean/parameterize RTL
        ↓
Clean directed testbench
        ↓
Add self-checking scoreboard
        ↓
Add randomized stimulus
        ↓
Add assertions
        ↓
Test corner cases
        ↓
Refactor and document results
```

The project should stop at this level before moving on to more advanced FIFO architectures. The goal is to build a strong verification foundation that can later be applied to UART, APB, and larger RTL projects.
