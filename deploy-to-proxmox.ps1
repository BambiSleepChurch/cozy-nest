# Cozy Nest - Automated Proxmox Deployment Script
# Target: 192.168.0.100

$PROXMOX_IP = "192.168.0.100"
$PROXMOX_USER = "root"

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  COZY NEST - AUTOMATED PROXMOX DEPLOYMENT" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Target Proxmox: $PROXMOX_IP" -ForegroundColor Yellow
Write-Host "User: $PROXMOX_USER" -ForegroundColor Yellow
Write-Host ""

# Check if ssh is available
$sshCheck = Get-Command ssh -ErrorAction SilentlyContinue
if (-not $sshCheck) {
    Write-Host "ERROR: SSH not found!" -ForegroundColor Red
    Write-Host "Install OpenSSH or use PuTTY" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative: Use Proxmox Web UI Shell" -ForegroundColor Yellow
    Write-Host "  1. Open https://$PROXMOX_IP:8006" -ForegroundColor Cyan
    Write-Host "  2. Login and click Shell button" -ForegroundColor Cyan
    Write-Host "  3. Run: cd /opt && git clone https://github.com/BambiSleepChurch/cozy-nest.git" -ForegroundColor Cyan
    Write-Host "  4. Run: cd cozy-nest && chmod +x scripts/deploy-nest.sh && ./scripts/deploy-nest.sh" -ForegroundColor Cyan
    exit 1
}

Write-Host "Step 1: Testing connection to Proxmox..." -ForegroundColor Green
Write-Host "  This will prompt for password..." -ForegroundColor Yellow
Write-Host ""

# Test connection
$testCmd = "echo 'Connection successful'"
Write-Host "Running: ssh ${PROXMOX_USER}@${PROXMOX_IP} '$testCmd'" -ForegroundColor Cyan
ssh "${PROXMOX_USER}@${PROXMOX_IP}" "$testCmd" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Cannot connect to Proxmox!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check Proxmox IP: $PROXMOX_IP" -ForegroundColor White
    Write-Host "  2. Verify SSH enabled on Proxmox" -ForegroundColor White
    Write-Host "  3. Try manual SSH: ssh ${PROXMOX_USER}@${PROXMOX_IP}" -ForegroundColor White
    Write-Host "  4. Or use Proxmox Web UI: https://${PROXMOX_IP}:8006" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "Step 2: Deploying Cozy Nest..." -ForegroundColor Green
Write-Host ""

# Create deployment commands
$deployCommands = @"
cd /opt &&
git clone https://github.com/BambiSleepChurch/cozy-nest.git 2>/dev/null || (cd cozy-nest && git pull) &&
cd cozy-nest &&
chmod +x scripts/deploy-nest.sh &&
./scripts/deploy-nest.sh
"@

Write-Host "Executing deployment on Proxmox..." -ForegroundColor Cyan
Write-Host ""

# Run deployment
ssh "${PROXMOX_USER}@${PROXMOX_IP}" "$deployCommands"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Check status: ssh ${PROXMOX_USER}@${PROXMOX_IP} 'pct status 100'" -ForegroundColor Cyan
    Write-Host "  2. Enter container: ssh ${PROXMOX_USER}@${PROXMOX_IP} 'pct enter 100'" -ForegroundColor Cyan
    Write-Host "  3. Or use Web UI: https://${PROXMOX_IP}:8006" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Red
    Write-Host "  DEPLOYMENT FAILED!" -ForegroundColor Red
    Write-Host "======================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check the error messages above" -ForegroundColor Yellow
    Write-Host "Or deploy manually via Web UI: https://${PROXMOX_IP}:8006" -ForegroundColor Yellow
}
