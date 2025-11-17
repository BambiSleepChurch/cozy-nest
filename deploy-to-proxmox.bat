@echo off
REM Cozy Nest - Quick Deploy to Proxmox 192.168.0.100

echo.
echo ======================================================================
echo   COZY NEST - DEPLOYING TO PROXMOX
echo ======================================================================
echo.
echo Target: 192.168.0.100
echo User: root
echo.
echo This will prompt for your Proxmox root password...
echo.

ssh root@192.168.0.100 "cd /opt && git clone https://github.com/BambiSleepChurch/cozy-nest.git 2>/dev/null || (cd cozy-nest && git pull) && cd cozy-nest && chmod +x scripts/deploy-nest.sh && ./scripts/deploy-nest.sh"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ======================================================================
    echo   DEPLOYMENT SUCCESSFUL!
    echo ======================================================================
    echo.
    echo Check status: ssh root@192.168.0.100 "pct status 100"
    echo Enter container: ssh root@192.168.0.100 "pct enter 100"
    echo Web UI: https://192.168.0.100:8006
    echo.
) else (
    echo.
    echo ======================================================================
    echo   DEPLOYMENT FAILED - See errors above
    echo ======================================================================
    echo.
    echo Alternative: Open https://192.168.0.100:8006 and use Web Shell
    echo.
)

pause
