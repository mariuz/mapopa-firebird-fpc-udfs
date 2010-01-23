@echo off

del /Q out\*.*

fpc fpc_udf.pp -FEout

