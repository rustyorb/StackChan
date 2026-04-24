@echo off
setlocal

set "ROOT_DIR=%~dp0"
set "SERVER_DIR=%ROOT_DIR%server"
set "PID_FILE=%SERVER_DIR%\.stackchan-server.pid"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$pidFile = '%PID_FILE%';" ^
  "$pidValue = if (Test-Path -LiteralPath $pidFile) { Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue } else { $null };" ^
  "$p = if ($pidValue) { Get-Process -Id $pidValue -ErrorAction SilentlyContinue } else { $null };" ^
  "if ($p) { Stop-Process -Id $p.Id; Write-Host \"StackChan server stopped: $($p.Id)\" } elseif ($pidValue) { Write-Host \"StackChan server process not running: $pidValue\" } else { Write-Host 'StackChan server PID file not found.' };" ^
  "$listeners = Get-NetTCPConnection -LocalPort 12800 -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique;" ^
  "foreach ($listenerPid in $listeners) { $listener = Get-Process -Id $listenerPid -ErrorAction SilentlyContinue; if ($listener) { Stop-Process -Id $listener.Id -Force; Write-Host \"StackChan server listener stopped: $($listener.Id)\" } };" ^
  "Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue"

endlocal
