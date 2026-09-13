# BMU UVM Verification Project

## Overview

This project implements a SystemVerilog UVM verification environment for a Bit Manipulation Unit (BMU). The verification environment was developed to validate the functional behavior of the BMU using directed testing, error scenario testing, constrained-random testing, stress testing, scoreboard-based checking, functional and code coverage, SystemVerilog Assertions (SVA), regression testing, and back-to-back transaction validation. The environment follows a standard UVM architecture where the Test starts a Sequence, the Sequence generates transactions for the Sequencer, the Driver converts those transactions into signal-level stimulus through the Interface, the DUT processes the inputs, and the Monitor observes the DUT activity and sends transactions to both the Scoreboard and Functional Coverage collector. SystemVerilog Assertions independently observe DUT and interface signals for temporal and protocol-level checks.

## Verification Architecture

```text
Test
  |
  v
Sequence
  |
  v
Sequencer
  |
  v
Driver
  |
  v
Interface
  |
  v
DUT
  |
  v
Monitor
  |
  +-------------------+
  |                   |
  v                   v
Scoreboard          Coverage

SVA directly observes DUT/interface signals.
```

## UVM Components

The `bmu_sequence_item.sv` file defines the transaction object containing the BMU stimulus and observed response fields. `bmu_sequencer.sv` manages the transaction flow between sequences and the driver. `bmu_driver.sv` receives transactions from the sequencer and drives the corresponding DUT inputs through a virtual interface. The driver supports back-to-back transactions so that a new transaction can be driven every clock cycle when an item is available. `bmu_monitor.sv` passively observes the DUT interface, reconstructs transactions, and publishes them through a UVM analysis port. The same monitored transaction is sent to the Scoreboard for correctness checking and to the Coverage component for functional coverage collection. `bmu_scoreboard.sv` implements the reference behavior of the verified BMU operations and compares the expected result and expected error behavior against the actual DUT outputs. `bmu_coverage.sv` implements the functional coverage model, including operation, valid, error, reset, error-type coverage, and a valid/error cross. `bmu_assertions.sv` contains SystemVerilog Assertions for temporal and protocol-level properties such as reset behavior, result hold behavior, invalid control combinations, and scan mode behavior.

## Verified Operations

The implemented verification scope includes 20 BMU operations: CSR Write Register, CSR Write Immediate, OR, ORN, XOR, XNOR, SRL, SRA, ROR, BINV, SH2ADD, SUB, SLT, SLTU, CTZ, CPOP, SEXT.B, MAX, PACK, and GREV.

## Verification Tests

The Directed Sanity Test verifies legal BMU operations using predetermined operands and expected behavior. The Error Test intentionally generates invalid control combinations to verify the DUT error handling, including CSR/AP conflicts, SH2ADD without ZBA, SUB with ZBA, OR+XOR, SRL+OR, SRA+OR, ROR+OR, BINV+OR, and GREV+OR conflicts. It also verifies that the DUT error behavior is independent of `valid_in`. The Constrained Random Test generates legal BMU operations with randomized operands to increase input diversity and explore combinations beyond the directed tests. The Stress Test extends the random verification with a much larger number of transactions and includes corner values, boundary shift values, repeated operations, reset insertion, `valid_in=0` scenarios, and constrained GREV stimulus. Stress testing was performed with both 2000 and 5000 transactions.

## Back-to-Back Verification

The driver was optimized to support true back-to-back transactions. Instead of inserting an idle clock cycle between consecutive transactions, the driver checks for a new sequence item at every driver clocking event and immediately drives the next transaction when one is available. This allows Transaction A, Transaction B, and Transaction C to execute on consecutive cycles. The optimization reduced the approximate runtime of the 5000-transaction stress test from 100035 ns to 50025 ns while preserving verification behavior.

## txn_active

The interface contains a testbench-only signal called `txn_active`. This signal is not part of the DUT specification and is used only by the verification environment to indicate that the testbench intentionally drove a transaction during a particular cycle. `valid_in` cannot be used for this purpose because `valid_in=0` is itself a meaningful verification scenario used to check result hold behavior and error independence. Therefore, `valid_in` remains a DUT functional signal while `txn_active` acts as a testbench bookkeeping signal that allows the monitor and assertions to distinguish an intentional transaction from an inactive testbench cycle.

## Functional Coverage

The final regression coverage databases from the sanity, error, random, and stress tests were merged using Cadence IMC. The implemented functional coverage model achieved **100.00% (41/41)** functional coverage. Additional reported metrics included 100.00% DUT Block Coverage, 100.00% DUT Expression Coverage, 63.86% DUT Toggle Coverage, 68.93% interface Toggle Coverage, 97.10% `i_result_ff` Toggle Coverage, and 53.85% SVA Assertion Coverage. Functional coverage closure does not mean that the DUT is bug-free. Functional coverage indicates whether the verification scenarios represented by the coverage model were exercised, while the Scoreboard and Assertions determine whether the DUT behaved correctly within those scenarios.

## Known DUT Issues

Verification identified several DUT defects. The CSR Write behavior shows reversed source selection between register and immediate cases. CTZ produces an incorrect trailing-zero count for some values, such as returning 9 instead of the expected 8 for `0x00000100`. CPOP operates incorrectly on the full 32-bit operand and was observed to count only part of the input. MAX produces an incorrect result due to incorrect operand behavior. PACK produces a reversed concatenation order. GREV produces incorrect byte-reversal behavior. The DUT also fails to assert `error` for several conflicting operation-control combinations, including OR+XOR, SRL+OR, SRA+OR, ROR+OR, BINV+OR, and GREV+OR. These failures are treated as identified DUT defects rather than failures of the UVM verification environment.

## Regression

The `run_regression.sh` script automates execution of the main verification suite, including the Sanity Test, Error Test, Random Test, and 5000-transaction Stress Test. Separate simulation logs and coverage databases are generated for the tests and can be merged using Cadence IMC to obtain the final regression coverage.

## Running the Project

The project uses Cadence Xcelium for simulation and Cadence IMC for coverage analysis. A typical UVM test can be executed using:

```bash
xrun -f filelist.f +UVM_TESTNAME=bmu_sanity_test
```

The random test can be executed using:

```bash
xrun -f filelist.f +UVM_TESTNAME=bmu_random_test
```

The stress test can be executed using:

```bash
xrun -f filelist.f +UVM_TESTNAME=bmu_stress_test
```

The stress transaction count can be overridden using:

```bash
xrun -f filelist.f +UVM_TESTNAME=bmu_stress_test +BMU_STRESS_N=5000
```

The complete regression can be executed using:

```bash
./run_regression.sh
```

## Final Coverage Merge

The regression coverage databases can be merged in Cadence IMC using:

```tcl
merge regression_sanity regression_error regression_random regression_stress -out bmu_final_regression
load -run bmu_final_regression
report -summary -metrics all
```

The final merged functional coverage result is **100.00% (41/41)**.

## Project Structure

```text
BMU/
├── Bit_Manipulation_Unit.sv
├── rtl_def.sv
├── rtl_defines.sv
├── rtl_lib.sv
├── rtl_param.sv
├── rtl_pdef.sv
├── library/
│   └── rtl_param.vh
├── bmu_interface.sv
├── bmu_sequence_item.sv
├── bmu_sequencer.sv
├── bmu_driver.sv
├── bmu_monitor.sv
├── bmu_agent.sv
├── bmu_env.sv
├── bmu_base_sequence.sv
├── bmu_directed_sequence.sv
├── bmu_reset_sequence.sv
├── bmu_sanity_sequence.sv
├── bmu_error_sequence.sv
├── bmu_random_sequence.sv
├── bmu_stress_sequence.sv
├── bmu_scoreboard.sv
├── bmu_coverage.sv
├── bmu_assertions.sv
├── bmu_base_test.sv
├── bmu_sanity_test.sv
├── bmu_error_test.sv
├── bmu_random_test.sv
├── bmu_stress_test.sv
├── bmu_tb_pkg.sv
├── bmu_top.sv
├── filelist.f
├── run_regression.sh
└── README.md
```

## Verification Status

Verification plan execution has been completed for the currently implemented verification scope. Directed verification, error verification, constrained-random verification, stress verification, back-to-back validation, SystemVerilog Assertions, regression execution, and functional coverage closure were completed. The functional coverage model reached 100%, while several DUT defects remain identified and documented. Therefore, the final result should not be interpreted as the DUT passing all verification. Instead, the planned verification activities for the implemented scope were completed, coverage closure was achieved for the implemented functional coverage model, and the remaining observed failures correspond to identified DUT defects.

## Tools

SystemVerilog, UVM, Cadence Xcelium, Cadence IMC, Git, and GitHub.

## Author

**Anas-Kmail**
