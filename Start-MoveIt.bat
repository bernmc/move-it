@echo off
REM ===================================================================
REM  Move It! launcher
REM  Double-click this to start the movement reminder.
REM  Runs PowerShell hidden (no console window) - no install needed.
REM ===================================================================
start "" /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0MoveIt.ps1"
