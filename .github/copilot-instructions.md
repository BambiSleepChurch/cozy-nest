# Copilot Instructions - The Cozy Nest Project

## Project Overview

**The Cozy Nest** is a containerized security monitoring infrastructure built on Proxmox VE using unprivileged Alpine Linux LXC containers. It provides network monitoring, file processing, and alert deployment in a minimal-footprint, security-hardened environment.

**Core Philosophy:** Tiny, Cozy, Secure - able to withstand any storm.

**Architecture Pattern:** Microservices within a single LXC container, communicating via filesystem and logs rather than network sockets. The Augment acts as the intelligent orchestrator.

## System Architecture

### Container Infrastructure

- **Platform:** Proxmox VE 7.0+ with LXC (not Docker)
- **Base OS:** Alpine Linux (~5MB base)
- **Security Model:** Unprivileged containers + AppArmor MAC
- **Default Container ID:** 100 (configurable in `deploy-nest.sh`)
- **Base Path:** `/opt/nest` inside container

### Service Components

All services are stateless where possible and communicate via filesystem:

1. **Augment** (`services/augment/augment.py`)
   - Python-based AI orchestrator (class: `NestAugment`)
   - Monitors all services via log files
   - Can invoke other services as shell commands
   - Provides health checks and natural language interface

2. **Dropbox Processor** (`services/dropbox/dropbox-processor.sh`)
   - inotify-based file monitoring
   - Three-stage processing: `incoming/` → `processing/` → `archive/`
   - Only `incoming/` is world-writable (777); others are restricted

3. **Flare System** (`services/flare-system/flare.sh`)
   - Multi-channel alert deployment (logs, email, webhooks)
   - Structured JSON logging to `flares.log`

4. **Probe Launcher** (`services/probe-launcher/probe.sh`)
   - Network scanning via nmap
   - Results written to `probes.log` with timestamps

5. **Communication Listener** (`services/listener/communication-listener.sh`)
   - Netcat-based network monitoring
   - Logs connections and received data

## Critical Developer Workflows

### Deployment (on Proxmox VE host)

```bash
cd /opt/cozy-nest
chmod +x scripts/*.sh
# CRITICAL: Review and change ROOT_PASSWORD in deploy-nest.sh first!
./scripts/deploy-nest.sh
```

**Common deployment issues:**
- Container ID 100 already exists → Script prompts for override
- AppArmor blocking operations → Check `dmesg | grep apparmor` in container
- File permissions wrong → Ensure `dropbox/incoming/` is 777, others are restricted

### Accessing the Container

```bash
# Enter container (Proxmox host)
pct enter 100

# Check status
pct status 100

# View logs inside container
tail -f /opt/nest/logs/*.log
```

### Testing Individual Services

Each service has a `test` command for validation:

```bash
# Inside container at /opt/nest
python3 ../services/augment/augment.py health
../services/dropbox/dropbox-processor.sh test
../services/flare-system/flare.sh test
../services/probe-launcher/probe.sh localhost ping
```

Always test individual components before integration.

### Starting All Services

```bash
# Inside container
/opt/nest/start-all.sh
```

## Code Conventions

### File Organization

```
nest/
├── scripts/          # Bash deployment scripts (.sh)
├── services/         # Service implementations
│   ├── augment/      # Python AI assistant
│   ├── listener/     # Bash network listener
│   ├── probe-launcher/ # Bash/nmap probes
│   ├── flare-system/ # Bash alert system
│   └── dropbox/      # Bash file processor
├── dropbox/          # File processing directories
│   ├── incoming/     # Upload here (chmod 777)
│   ├── processing/   # Active processing
│   └── archive/      # Completed files
├── logs/             # Centralized logging
└── docs/             # Markdown documentation
```

### Naming Conventions

- **Scripts:** `kebab-case.sh` (e.g., `deploy-nest.sh`, `dropbox-processor.sh`)
- **Python modules:** `snake_case.py` (e.g., `augment.py`)
- **Service names:** Lowercase with hyphens (e.g., `bambisleep-nest`)
- **Log files:** Component-based (e.g., `dropbox.log`, `flares.log`)

### Code Style

**Bash scripts:**
```bash
#!/bin/bash
set -e  # Always fail on errors
# Descriptive header explaining purpose
```

**Python:**
- Follow PEP 8
- Use `logging` module for all output (no print statements)
- Standard library only (avoid external dependencies)

**Security:**
- Unprivileged containers ALWAYS (never set privileged=1)
- AppArmor enabled unless documented exception
- Minimal network permissions per service

## Data Flow Patterns

1. **File Processing:** Files → `dropbox/incoming/` → inotify trigger → move to `processing/` → process → `archive/`
2. **Alerts:** Service event → call `flare.sh` → log to `flares.log` + optional external channels
3. **Network Scanning:** Command → `probe.sh` → nmap execution → results to `probes.log`
4. **Orchestration:** Augment monitors logs → detects events → invokes appropriate service

## Integration Points

### External Access

- **HTTP API (port 8080):** Communication listener accepts JSON payloads
- **SSH:** Direct container access via `pct enter` or SSH (if enabled)
- **File Uploads:** Drop files in `/opt/nest/dropbox/incoming/` via SFTP/SMB/NFS

### Notification Channels

Configurable in flare system:
- Log files (default, always enabled)
- Email via SMTP (to be implemented)
- Webhooks HTTP POST (to be implemented)
- Slack/Discord API (to be implemented)

## Common Pitfalls & Solutions

1. **Forgot to change ROOT_PASSWORD:** Always review `deploy-nest.sh` before deploying
2. **AppArmor blocking operations:** Check `dmesg | grep apparmor` if services fail mysteriously
3. **Wrong file permissions:** `incoming/` needs 777, but `processing/`/`archive/` should be restricted
4. **Running as privileged:** Never do this; defeats the entire security model
5. **Scripts not executable:** Use `chmod +x` on all `.sh` files before running
6. **Hardcoded paths:** Scripts assume `/opt/nest` base; changing requires updates across multiple files
7. **Container ID conflicts:** Default is 100; script prompts for override if exists

## Project-Specific Patterns

### Why Alpine Linux?
Minimal attack surface (~5MB base), fast boot times, secure apk package manager.

### Why Unprivileged Containers?
Security by design - container escapes affect unprivileged user, not root. This is the default and should NEVER be changed without documented justification.

### Why Filesystem Communication?
Simpler than network sockets, easier to debug, more secure (no listening ports between services).

### The Augment's Role
Intelligent orchestrator that reads logs, processes natural language commands, and triggers automated responses to events.

## Key Dependencies

**Container (Alpine Linux):**
- `bash`, `python3`, `py3-pip` - Core runtimes
- `nmap`, `tcpdump` - Network tools
- `inotify-tools` - File monitoring
- `openssh` - Remote access
- `supervisor` - Process management (optional)

**Python packages (Augment):**
- Standard library only: `json`, `logging`, `pathlib`, `datetime`, `os`, `sys`, `time`
- Future: `requests`, `flask` for HTTP API

## Documentation References

- **Setup Guide:** `docs/SETUP.md` - Step-by-step deployment with screenshots
- **Quick Start:** `QUICKSTART.md` - Rapid deployment commands
- **Deployment Checklist:** `DEPLOYMENT_CHECKLIST.txt` - Pre-deployment verification
- **File Index:** `FILE_INDEX.md` - Complete file listing with descriptions

---

**For Mr. Magoo:** See `docs/SETUP.md` for big friendly letters and pictures! 👓
