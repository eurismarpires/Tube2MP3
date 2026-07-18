@echo off
setlocal
call "C:\Program Files (x86)\Embarcadero\Studio\21.0\bin\rsvars.bat"
if errorlevel 1 exit /b 1

if not exist work\tests mkdir work\tests
powershell -NoProfile -ExecutionPolicy Bypass -File tests\ValidateProject.ps1
if errorlevel 1 exit /b 1
dcc32 -B -Ework\tests tests\Tube2MP3Tests.dpr
if errorlevel 1 exit /b 1
work\tests\Tube2MP3Tests.exe
if errorlevel 1 exit /b 1

msbuild Tube2MP3.dproj /t:Build /p:Config=Debug /p:Platform=Win32 /v:minimal
if errorlevel 1 exit /b 1
msbuild Tube2MP3.dproj /t:Build /p:Config=Release /p:Platform=Win32 /v:minimal
if errorlevel 1 exit /b 1

echo Build e testes concluidos.
