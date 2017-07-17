# This file must be sourced.

# Assume you install the mesa drivers in your HOME
# If not, update the following:
MESADIR="$HOME/@MESA_PACKAGE@"

LD_LIBRARY_PATH="$MESADIR"
export LD_LIBRARY_PATH
LIBGL_DRIVERS_PATH="$MESADIR"
export LIBGL_DRIVERS_PATH

GCOV_PREFIX_STRIP=2
export GCOV_PREFIX_STRIP
GCOV_PREFIX=$MESADIR/coverage
export GCOV_PREFIX
