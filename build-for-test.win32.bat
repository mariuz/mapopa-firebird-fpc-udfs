@echo off

del /Q out\*.*

fpc fpc_udf.pp -g -gc -gl -dUSE_C_MALLOC -FEout
fpc fpc_udf_test.pp -FEout
out\fpc_udf_test

