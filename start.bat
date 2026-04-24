@echo off
setlocal

set "ROOT_DIR=%~dp0"
set "SERVER_DIR=%ROOT_DIR%server"
set "PID_FILE=%SERVER_DIR%\.stackchan-server.pid"
set "LOG_FILE=%SERVER_DIR%\.stackchan-server.log"
set "ERR_FILE=%SERVER_DIR%\.stackchan-server.err.log"
set "BIN_FILE=%SERVER_DIR%\.stackchan-server.exe"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$pidFile = '%PID_FILE%'; $logFile = '%LOG_FILE%'; $errFile = '%ERR_FILE%'; $serverDir = '%SERVER_DIR%'; $binFile = '%BIN_FILE%';" ^
  "if (Test-Path -LiteralPath $pidFile) { $oldPid = Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue; if ($oldPid -and (Get-Process -Id $oldPid -ErrorAction SilentlyContinue)) { Write-Host \"StackChan server already running: $oldPid\"; exit 0 } }" ^
  "Push-Location $serverDir; go build -o $binFile main.go; if ($LASTEXITCODE -ne 0) { Pop-Location; exit $LASTEXITCODE }; Pop-Location;" ^
  "$p = Start-Process -FilePath $binFile -WorkingDirectory $serverDir -RedirectStandardOutput $logFile -RedirectStandardError $errFile -PassThru -WindowStyle Hidden;" ^
  "Set-Content -LiteralPath $pidFile -Value $p.Id;" ^
  "Write-Host \"StackChan server started: $($p.Id)\"; Write-Host \"Log: $logFile\"; Write-Host \"Error log: $errFile\""

endlocal
