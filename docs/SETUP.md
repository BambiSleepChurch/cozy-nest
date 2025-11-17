# 📚 SETUP GUIDE FOR MR. MAGOO

## Step-by-Step Instructions in BIG FRIENDLY LETTERS

---

## 🎯 WHAT YOU'RE BUILDING

A secure, containerized monitoring and automation system running on Proxmox VE.

**The Nest includes:**

1. 🛡️ Security container (BambiSleep)
2. 📡 Communication listener
3. 🔍 Network probe launcher
4. 🎆 Alert system (Flares)
5. 📦 File processing dropbox
6. 🤖 AI assistant (The Augment)

---

## ⚠️ PREREQUISITES

Before you start, you need:

- ✅ **Proxmox VE 7.0 or newer** installed and running
- ✅ **SSH access** to your Proxmox host
- ✅ **At least 8GB free storage** for the container
- ✅ **2GB RAM** available
- ✅ **Basic Linux knowledge** (helpful but not required)

---

## 📝 STEP-BY-STEP INSTALLATION

### STEP 1: Get the Nest Files

On your Proxmox host, download or copy the nest files:

```bash
# If you have the files on a USB drive:
mkdir -p /opt/cozy-nest
cp -r /path/to/nest/files/* /opt/cozy-nest/

# Or clone from git (if using git):
cd /opt
git clone <your-repo> cozy-nest
cd cozy-nest
```

### STEP 2: Make Scripts Executable

```bash
chmod +x scripts/*.sh
chmod +x services/**/*.sh
chmod +x services/**/*.py
```

### STEP 3: Review Configuration

**IMPORTANT:** Open the deployment script and change the password!

```bash
nano scripts/deploy-nest.sh

# Find this line:
# ROOT_PASSWORD="ChangeMe123!"
# Change it to a strong password!
```

### STEP 4: Run the Deployment

```bash
cd /opt/cozy-nest
./scripts/deploy-nest.sh
```

**What happens:**

- ✅ Downloads Alpine Linux template
- ✅ Creates unprivileged container
- ✅ Installs all required packages
- ✅ Sets up directory structure
- ✅ Configures security settings

This takes about **5-10 minutes** depending on your internet speed.

### STEP 5: Enter Your Nest

```bash
pct enter 100
```

You're now inside the container! 🎉

### STEP 6: Deploy Services

Inside the container:

```bash
# Copy service files from host
# (These will be copied during deployment)

cd /opt/nest

# Make scripts executable
chmod +x services/*/**.sh
chmod +x services/*/*.py

# Test the augment
python3 services/augment/augment.py health
```

### STEP 7: Start Services

Create a simple service runner:

```bash
# Create start script
cat > /opt/nest/start-all.sh << 'EOF'
#!/bin/bash

echo "🏠 Starting all nest services..."

# Start dropbox monitor
nohup /opt/nest/../services/dropbox/dropbox-processor.sh monitor > /dev/null 2>&1 &
echo "✅ Dropbox processor started"

# Start communication listener
nohup /opt/nest/../services/listener/communication-listener.sh > /dev/null 2>&1 &
echo "✅ Communication listener started"

# Start flare monitor
nohup /opt/nest/../services/flare-system/flare.sh monitor > /dev/null 2>&1 &
echo "✅ Flare system started"

# Start augment
nohup python3 /opt/nest/../services/augment/augment.py monitor > /dev/null 2>&1 &
echo "✅ Augment started"

echo ""
echo "🎉 All services running!"
echo "   Use 'ps aux | grep -E \"dropbox|listener|flare|augment\"' to check status"
EOF

chmod +x /opt/nest/start-all.sh

# Start everything
/opt/nest/start-all.sh
```

---

## 🧪 TESTING YOUR NEST

### Test 1: Check Health

```bash
python3 /opt/nest/../services/augment/augment.py health
```

Expected output: JSON with system status

### Test 2: Test Dropbox

```bash
# Create a test file
echo "Hello Nest!" > /opt/nest/dropbox/incoming/test.txt

# Check logs
tail -f /opt/nest/logs/dropbox.log
```

You should see the file being processed!

### Test 3: Deploy a Flare

```bash
/opt/nest/../services/flare-system/flare.sh send "Test alert" INFO
```

You should see a notification in the logs.

### Test 4: Launch a Probe

```bash
/opt/nest/../services/probe-launcher/probe.sh 8.8.8.8 ping
```

This will probe Google's DNS server.

### Test 5: Interactive Augment

```bash
python3 /opt/nest/../services/augment/augment.py
```

Try commands:

- `health` - Check system
- `status` - Show nest status
- `flare` - Deploy a flare
- `quit` - Exit

---

## 📡 ACCESSING FROM OUTSIDE

### Web Interface (Port 8080)

The nest listens on port 8080. To access from outside:

```bash
# Find container IP
pct exec 100 -- ip addr show eth0

# Test from Proxmox host
curl http://<container-ip>:8080
```

### SSH Access

```bash
# From Proxmox host
pct enter 100

# Or enable SSH in container:
pct exec 100 -- ash -c "rc-update add sshd; rc-service sshd start"
```

---

## 🔒 SECURITY CHECKLIST

Before going to production:

- [ ] Changed default password
- [ ] Reviewed AppArmor profiles
- [ ] Configured firewall rules
- [ ] Set up backup schedule
- [ ] Tested all services
- [ ] Reviewed log rotation
- [ ] Configured notifications
- [ ] Documented custom changes

---

## 🛠️ MAINTENANCE

### Daily Tasks

```bash
# Check health
python3 /opt/nest/../services/augment/augment.py health

# View recent logs
tail -n 50 /opt/nest/logs/*.log
```

### Weekly Tasks

```bash
# Clean old archives
/opt/nest/../services/dropbox/dropbox-processor.sh cleanup 30

# Update packages
apk update && apk upgrade
```

### Monthly Tasks

```bash
# Backup configuration
tar -czf /var/backups/nest-config-$(date +%F).tar.gz /opt/nest/config

# Review security logs
grep -i "security\|fail\|error" /opt/nest/logs/*.log
```

---

## 🚨 TROUBLESHOOTING

### Problem: Container won't start

```bash
# Check container status
pct status 100

# View container config
cat /etc/pve/lxc/100.conf

# Try manual start with errors
pct start 100
```

### Problem: Services not responding

```bash
# Check if services are running
ps aux | grep -E "dropbox|listener|flare|augment"

# Restart services
/opt/nest/start-all.sh
```

### Problem: Dropbox not processing files

```bash
# Check dropbox logs
tail -f /opt/nest/logs/dropbox.log

# Verify inotify is working
which inotifywait

# Test manually
/opt/nest/../services/dropbox/dropbox-processor.sh test
```

### Problem: Can't access from outside

```bash
# Check firewall
iptables -L -n

# Check if service is listening
netstat -tlnp | grep 8080

# Test locally first
curl http://localhost:8080
```

---

## 📞 GETTING HELP

If something isn't working:

1. **Check the logs** in `/opt/nest/logs/`
2. **Test each component** individually
3. **Review the security settings** - AppArmor might be blocking something
4. **Check system resources** - Out of memory/disk?

---

## 🎓 LEARNING MORE

Recommended reading:

- Proxmox VE Documentation: https://pve.proxmox.com/wiki/
- LXC Container Guide: https://pve.proxmox.com/wiki/Linux_Container
- Alpine Linux Handbook: https://docs.alpinelinux.org/

---

## ✨ YOU'RE DONE!

Your cozy nest is now ready to weather any storm! 🏠⛈️

Remember:

- 🛡️ Security first, always
- 📝 Check logs regularly
- 🔄 Keep systems updated
- 💾 Backup your configuration

**Welcome home!** 🎉
