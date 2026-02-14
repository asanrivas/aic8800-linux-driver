#!/bin/bash
# Applied before every DKMS build to fix kernel API incompatibilities.
# Safe to run repeatedly (all fixes are idempotent).

SRC="drivers/aic8800/aic8800_fdrv/rwnx_rx.c"

# Fix: in_irq() removed in kernel 5.14+ → replaced by in_hardirq()
sed -i 's/in_irq()/in_hardirq()/g' "$SRC"
