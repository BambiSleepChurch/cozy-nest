# 📁 FILE INDEX - What Each File Does

This is your complete guide to every file in The Cozy Nest project.

---

## 📚 DOCUMENTATION FILES

### `README.md` (Main Overview)

**Size:** ~5.4 KB  
**Purpose:** Project overview and high-level introduction  
**When to read:** First thing! Get the big picture here  
**Key sections:**

- What is The Cozy Nest
- Component descriptions
- Quick start instructions
- Project philosophy

### `QUICKSTART.md` (This is for YOU, Mr. Magoo!)

**Size:** ~8.0 KB  
**Purpose:** Super simple guide to get started fast  
**When to read:** When you want to deploy NOW  
**Key sections:**

- What each component does (simple explanations)
- File structure diagram
- Copy-paste commands
- Common tasks
- Troubleshooting

### `docs/SETUP.md` (Detailed Instructions)

**Size:** ~7.2 KB  
**Purpose:** Step-by-step deployment guide with BIG LETTERS  
**When to read:** When deploying for the first time  
**Key sections:**

- Prerequisites checklist
- Installation steps (very detailed)
- Testing procedures
- Accessing from outside
- Maintenance schedules

### `.github/copilot-instructions.md` (For AI Assistants)

**Size:** ~7.1 KB  
**Purpose:** Instructions for AI coding agents (like GitHub Copilot)  
**When to read:** If you're an AI or want to understand the codebase deeply  
**Key sections:**

- Architecture patterns
- Code conventions
- Security model
- Common pitfalls

---

## 🔧 DEPLOYMENT SCRIPTS

### `scripts/deploy-nest.sh`

**Size:** ~4.8 KB  
**Language:** Bash  
**Purpose:** Main deployment script - creates everything on Proxmox  
**What it does:**

1. ✅ Checks for Proxmox VE
2. ✅ Downloads Alpine Linux template
3. ✅ Creates unprivileged LXC container (ID: 100)
4. ✅ Installs all required packages
5. ✅ Sets up directory structure
6. ✅ Configures security (AppArmor, CGroups)

**Important variables to change:**

- `ROOT_PASSWORD` - nyks=strix=rog=zzz=490=€
- `CONTAINER_ID` - Default is 169
- `MEMORY` - Default is 48 MB
- `DISK_SIZE` - Default is 1.2 GB
- `NETWORK_BRIDGE` - Default is `vmbr0`

**How to use:**

```bash
cd /opt/cozy-nest
chmod +x scripts/deploy-nest.sh
nano scripts/deploy-nest.sh  # Change ROOT_PASSWORD!
./scripts/deploy-nest.sh
```

---

## 🤖 SERVICE SCRIPTS

### `services/augment/augment.py`

**Size:** ~11.1 KB  
**Language:** Python 3  
**Purpose:** AI assistant that orchestrates all nest components  
**What it does:**

- 🔍 Monitors system health
- 👀 Watches dropbox for files
- 🎆 Deploys flares (alerts)
- 🔍 Launches network probes
- 📡 Listens for communications
- 🎮 Interactive command interface

**Commands:**

- `python3 augment.py` - Interactive mode
- `python3 augment.py health` - Check system
- `python3 augment.py monitor` - Watch dropbox
- `python3 augment.py listen` - Start listener
- `python3 augment.py flare "msg"` - Send alert
- `python3 augment.py probe <target>` - Scan target

**Dependencies:**

- Python 3 standard library only
- No external packages required (yet)

### `services/listener/communication-listener.sh`

**Size:** ~714 bytes  
**Language:** Bash  
**Purpose:** Listens for incoming network communications on port 8080  
**What it does:**

- 📡 Opens HTTP listener on port 8080
- 📝 Logs all incoming connections
- 📨 Responds with JSON status
- ⏰ Runs continuously in background

**How to use:**

```bash
# Run in background
nohup ./communication-listener.sh &

# View logs
tail -f /opt/nest/logs/listener.log
```

**Port:** 8080 (HTTP)  
**Protocol:** Simple HTTP server (uses netcat)

### `services/probe-launcher/probe.sh`

**Size:** ~2.1 KB  
**Language:** Bash  
**Purpose:** Launches network reconnaissance probes  
**What it does:**

- 🏓 Ping probes (basic reachability)
- 🔌 Port scans (common ports)
- 🔎 Service detection (identify services)
- 👻 Stealth scans (ultra-quiet)

**Probe types:**

- `ping` - Simple ICMP ping (3 packets)
- `port` - Scan top 100 ports with nmap
- `service` - Detect service versions
- `stealth` - Ultra-low profile scan (T1 timing)

**How to use:**

```bash
./probe.sh <target> [type]

# Examples:
./probe.sh 192.168.1.1 ping
./probe.sh bambi.bambisleep.church 6969
./probe.sh 10.0.0.1 service
./probe.sh 172.16.0.1 stealth
```

**Dependencies:**

- `nmap` - Network scanner
- `ping` - ICMP utility

**Logs:** `/opt/nest/logs/probes.log`

### `services/flare-system/flare.sh`

**Size:** ~3.1 KB  
**Language:** Bash  
**Purpose:** Alert deployment and system monitoring  
**What it does:**

- 🎆 Sends alerts with severity levels
- 📊 Monitors disk space, memory, file queue
- 📝 Logs all flares in JSON format
- 🚨 Visual notifications (colored output)

**Severity levels:**

- `INFO` - General information (💡)
- `WARNING` - Something needs attention (⚠️)
- `CRITICAL` - Urgent issue (🚨)

**Commands:**

- `send <message> [severity]` - Send a flare
- `monitor` - Start continuous monitoring
- `test` - Send a test flare

**How to use:**

```bash
./flare.sh send "System started" INFO
./flare.sh send "Low disk space" WARNING
./flare.sh send "Intrusion detected!" CRITICAL
./flare.sh monitor  # Runs continuously
```

**Monitoring intervals:**

- Disk space check: Every 60 seconds
- Memory check: Every 60 seconds
- File queue check: Every 60 seconds

**Logs:** `/opt/nest/logs/flares.log`

### `services/dropbox/dropbox-processor.sh`

**Size:** ~4.4 KB  
**Language:** Bash  
**Purpose:** Automated file monitoring and processing  
**What it does:**

- 👀 Watches `/opt/nest/dropbox/incoming/` with inotify
- 🔄 Moves files to processing directory
- 📝 Detects file types (text, JSON, images, archives)
- 📦 Archives processed files with timestamps
- 🎆 Deploys flares for important files

**File types handled:**

- Text files (`text/*`)
- JSON files (`application/json`)
- Images (`image/*`)
- Archives (`zip`, `tar`, `gzip`)

**Directory structure:**

- `incoming/` - Drop files here (chmod 777)
- `processing/` - Files currently being processed
- `archive/` - Completed files (timestamped)

**Commands:**

- `monitor` - Start watching dropbox (default)
- `cleanup [days]` - Remove old archives (default: 30 days)
- `test` - Create a test file

**How to use:**

```bash
# Start monitoring
./dropbox-processor.sh monitor

# Clean old archives
./dropbox-processor.sh cleanup 30

# Test
./dropbox-processor.sh test
```

**Dependencies:**

- `inotify-tools` - File system monitoring
- `file` - File type detection

**Logs:** `/opt/nest/logs/dropbox.log`

---

## 📊 FILE SUMMARY

| Category          | Files        | Total Size   | Purpose                 |
| ----------------- | ------------ | ------------ | ----------------------- |
| **Documentation** | 4 files      | ~27.8 KB     | Guides and instructions |
| **Deployment**    | 1 file       | ~4.8 KB      | Container creation      |
| **Services**      | 5 files      | ~21.4 KB     | Core functionality      |
| **TOTAL**         | **10 files** | **~54.0 KB** | Complete system         |

---

## 🎯 WHERE TO START

### If you're deploying for the first time:

1. Read `QUICKSTART.md` (this file!)
2. Follow `docs/SETUP.md` step-by-step
3. Run `scripts/deploy-nest.sh`
4. Test with `services/augment/augment.py`

### If you want to understand the code:

1. Read `.github/copilot-instructions.md`
2. Review `services/augment/augment.py` (main orchestrator)
3. Check individual service scripts

### If you just want to use it:

1. Run `scripts/deploy-nest.sh`
2. Use `python3 augment.py` for interactive mode
3. Drop files in dropbox, deploy flares, launch probes!

---

## 🔗 FILE RELATIONSHIPS

```
deploy-nest.sh
    ↓ Creates container and installs packages
    ↓
augment.py (Main Coordinator)
    ↓ Can invoke all other services
    ├─→ communication-listener.sh (monitors network)
    ├─→ probe.sh (scans targets)
    ├─→ flare.sh (sends alerts)
    └─→ dropbox-processor.sh (handles files)
```

---

## 💡 PRO TIPS

### Making Changes

- **Deployment script:** Edit `scripts/deploy-nest.sh` to change container specs
- **Service behavior:** Edit individual scripts in `services/`
- **Augment logic:** Modify `services/augment/augment.py`

### Adding Features

- **New notification channels:** Edit `flare.sh` to add email/SMS/webhooks
- **File processing:** Customize `dropbox-processor.sh` for specific file types
- **Probe types:** Add new probe modes to `probe.sh`
- **Augment commands:** Extend `augment.py` with new functions

### Debugging

- All services log to `/opt/nest/logs/`
- Use `tail -f /opt/nest/logs/*.log` to watch live
- Check AppArmor: `dmesg | grep apparmor`
- Test services individually before running together

---

## 📝 FILE SIZES EXPLAINED

**Why so small?**

- Bash scripts are tiny and efficient
- Python uses standard library only
- No bloated frameworks or dependencies
- Following the "tiny, cozy" philosophy!

**Total project size:** ~54 KB of code
**Running container size:** ~8 GB (includes Alpine Linux + packages)
**Memory usage:** ~100-200 MB when all services running

---

## 🎉 YOU'RE READY!

You now know what every file does and how they work together.

**Next step:** Run `./scripts/deploy-nest.sh` and build your nest! 🏠

---

**Remember:** Start with `QUICKSTART.md` if you get lost! 👓
