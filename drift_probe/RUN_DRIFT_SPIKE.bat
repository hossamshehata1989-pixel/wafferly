@echo off
setlocal
cd /d "%~dp0"

echo ============================================
echo Wafferly - Drift isolated codegen probe
echo ============================================
echo.

where dart >nul 2>nul
if errorlevel 1 (
  echo ERROR: Dart was not found in PATH.
  echo Install Flutter/Dart or add Flutter\bin to PATH, then reopen this window.
  pause
  exit /b 1
)

echo [1/4] Dart version
dart --version
if errorlevel 1 goto :failed

echo.
echo [2/4] Resolving packages...
dart pub get
if errorlevel 1 goto :failed

echo.
echo [3/4] Running Drift code generation...
dart run build_runner build --delete-conflicting-outputs
if errorlevel 1 goto :failed

echo.
echo [4/4] Running probe...
dart run bin/run_probe.dart
if errorlevel 1 goto :failed

echo.
echo SUCCESS: all commands completed. Review the output above.
pause
exit /b 0

:failed
echo.
echo FAILED: a command returned an error. Copy the full terminal output and send it for review.
pause
exit /b 1
