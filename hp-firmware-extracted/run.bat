@echo off
pushd "%~dp0"
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OS=32BIT || set OS=64BIT

IF %OS%==32BIT (
   pushd DPInst\X32
   DPInst.exe /q /a
) ELSE (   
   pushd DPInst\X64
   DPInst.exe /q /a
)

popd 
start EnterpriseDU.exe

