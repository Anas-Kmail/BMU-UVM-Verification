#!/bin/bash

# ============================================================
# BMU UVM Regression Script
#
# Runs:
#   1. Sanity Test
#   2. Error Test
#   3. Random Test
#   4. Stress Test - 5000 transactions
#
# Each test gets:
#   - its own coverage database
#   - its own log file
# ============================================================


echo "============================================================"
echo "              BMU UVM REGRESSION START"
echo "============================================================"


# ------------------------------------------------------------
# Create directory for regression logs
# ------------------------------------------------------------
mkdir -p regression_logs


# ============================================================
# 1. SANITY TEST
# ============================================================

echo ""
echo "============================================================"
echo "Running SANITY TEST"
echo "============================================================"

xrun -64bit -sv -uvm \
  -incdir . \
  -incdir library \
  -f filelist.f \
  -top bmu_top \
  +UVM_TESTNAME=bmu_sanity_test \
  -coverage all \
  -covtest regression_sanity \
  -l regression_logs/sanity.log


# ============================================================
# 2. ERROR TEST
# ============================================================

echo ""
echo "============================================================"
echo "Running ERROR TEST"
echo "============================================================"

xrun -64bit -sv -uvm \
  -incdir . \
  -incdir library \
  -f filelist.f \
  -top bmu_top \
  +UVM_TESTNAME=bmu_error_test \
  -coverage all \
  -covtest regression_error \
  -l regression_logs/error.log


# ============================================================
# 3. CONSTRAINED RANDOM TEST
# ============================================================

echo ""
echo "============================================================"
echo "Running RANDOM TEST"
echo "============================================================"

xrun -64bit -sv -uvm \
  -incdir . \
  -incdir library \
  -f filelist.f \
  -top bmu_top \
  +UVM_TESTNAME=bmu_random_test \
  -coverage all \
  -covtest regression_random \
  -l regression_logs/random.log


# ============================================================
# 4. STRESS TEST
# ============================================================

echo ""
echo "============================================================"
echo "Running STRESS TEST - 5000 TRANSACTIONS"
echo "============================================================"

xrun -64bit -sv -uvm \
  -incdir . \
  -incdir library \
  -f filelist.f \
  -top bmu_top \
  +UVM_TESTNAME=bmu_stress_test \
  +BMU_STRESS_N=5000 \
  -coverage all \
  -covtest regression_stress \
  -l regression_logs/stress.log


# ============================================================
# REGRESSION COMPLETE
# ============================================================

echo ""
echo "============================================================"
echo "              BMU UVM REGRESSION COMPLETE"
echo "============================================================"

echo ""
echo "Logs saved in:"
echo "  regression_logs/sanity.log"
echo "  regression_logs/error.log"
echo "  regression_logs/random.log"
echo "  regression_logs/stress.log"

echo ""
echo "Coverage runs:"
echo "  regression_sanity"
echo "  regression_error"
echo "  regression_random"
echo "  regression_stress"

echo "============================================================"