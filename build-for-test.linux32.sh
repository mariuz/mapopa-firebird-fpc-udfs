#!/bin/bash

fpc fpc_udf.pas -Fu/lib/fpc/2.2.2/units/i386-linux/hash
fpc fpc_udf_test.pas

export LD_LIBRARY_PATH=.
./fpc_udf_test

