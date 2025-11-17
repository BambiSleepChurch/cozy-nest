# Copilot Instructions - The Cozy Nest Project

## Project Overview

**The Cozy Nest** is a secure, containerized monitoring and automation infrastructure built on Proxmox VE with LXC containers. It provides a minimal-footprint security system capable of monitoring networks, processing files, and deploying alerts.

**Core Philosophy:** Tiny, Cozy, Secure - able to withstand any storm.

**Key Components:**

- 🛡️ **BambiSleep Security Container** - Unprivileged Alpine Linux LXC with AppArmor isolation
- 📡 **Communication Listener** - Network monitoring and connection logging service
- 🔍 **Probe Launcher** - Stealth network scanning and reconnaissance tools
- 🎆 **Flare System** - Multi-channel alert and notification deployment
- 📦 **Dropbox Processor** - Automated file monitoring with inotify and processing pipelines
- 🤖 **The Augment** - Python-based AI assistant for nest management

## Development Workflow

### Deployment (on Proxmox VE host)

```bash
cd /opt/cozy-nest
chmod +x scripts/*.sh
# Review and change ROOT_PASSWORD in deploy-nest.sh first!
./scripts/deploy-nest.sh
```

### Accessing the Nest

```bash
# Enter container
pct enter 100

# Check status
pct status 100
```

### Testing Services

```bash
# Inside container at /opt/nest
python3 ../services/augment/augment.py health
../services/dropbox/dropbox-processor.sh test
../services/flare-system/flare.sh test
../services/probe-launcher/probe.sh localhost ping
```

### Starting All Services

```bash
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
├── containers/       # LXC configs (future)
├── dropbox/          # File processing directories
│   ├── incoming/     # Upload here (chmod 777)
│   ├── processing/   # Active processing
│   └── archive/      # Completed files
└── docs/             # Markdown documentation
```

### Naming Conventions

- **Scripts:** `kebab-case.sh` (e.g., `deploy-nest.sh`, `dropbox-processor.sh`)
- **Python modules:** `snake_case.py` (e.g., `augment.py`)
- **Service names:** Lowercase with hyphens (e.g., `bambisleep-nest`)
- **Log files:** Component-based (e.g., `dropbox.log`, `flares.log`)
- **Container ID:** Default is 100 (configurable in deployment script)

### Code Style

- **Bash scripts:** Always use `set -e` for error handling, include descriptive headers
- **Python:** Follow PEP 8, use logging module for all output
- **Security:** Unprivileged containers ALWAYS, AppArmor enabled unless documented exception
- **Logging:** Structured JSON for important events, human-readable for general logs

## Architecture Patterns

### Component Structure

Each service runs independently within the Alpine LXC container:

- Services are **stateless** where possible
- Communication via filesystem (`/opt/nest/dropbox`) and logs
- The Augment acts as orchestrator and can invoke other services
- All services log to `/opt/nest/logs/` for centralized monitoring

### Data Flow

1. Files arrive in `/opt/nest/dropbox/incoming/` (watched by inotify)
2. Dropbox processor moves to `processing/`, handles file, archives to `archive/`
3. Flares are logged to `flares.log` and displayed to console/sent to channels
4. Probes write results to `probes.log` with timestamp and target info
5. Augment monitors all logs and can trigger actions based on events

### Security Model

- **Unprivileged containers** - UID 0 inside maps to unprivileged UID outside
- **AppArmor** - Mandatory access control restricts dangerous syscalls
- **CGroups** - Resource limits prevent resource exhaustion
- **Network isolation** - Each component has minimal network permissions
- **File permissions** - Only `incoming/` is world-writable; others are restricted

## Key Dependencies

**Container (Alpine Linux):**

- `bash` - Service scripts
- `python3` + `py3-pip` - Augment AI assistant
- `nmap` - Network probing
- `tcpdump` - Packet capture
- `inotify-tools` - File monitoring
- `openssh` - Remote access
- `supervisor` - Process management (optional)

**Python packages (for Augment):**

- Standard library only (json, logging, pathlib, datetime)
- Future: requests, flask for HTTP API

## Integration Points

### External Access

- **HTTP API (port 8080):** Communication listener receives JSON payloads
- **SSH:** Direct container access via `pct enter` or SSH after enabling
- **File uploads:** Drop files in `/opt/nest/dropbox/incoming/` via SFTP/SMB/NFS

### Notification Channels (configurable in flare system)

- Log files (default)
- Email (SMTP - to be implemented)
- Webhooks (HTTP POST - to be implemented)
- Slack/Discord (API - to be implemented)

### Proxmox Integration

- Uses `pct` CLI for container management
- Container config in `/etc/pve/lxc/100.conf`
- Uses Proxmox storage for container rootfs

## Common Pitfalls

1. **Forgetting to change ROOT_PASSWORD** in deployment script - always review before deploying
2. **AppArmor blocking operations** - Check `dmesg | grep apparmor` if services fail mysteriously
3. **File permissions in dropbox** - `incoming/` needs 777, but processing/archive should be restricted
4. **Running as privileged** - Never do this; defeats the security model
5. **Not making scripts executable** - Use `chmod +x` on all `.sh` files
6. **Hardcoded paths** - Scripts assume `/opt/nest` base directory; changing requires updates
7. **Container ID conflicts** - Deployment fails if container 100 exists; script prompts for override

## Helpful Context

### Why Alpine Linux?

Minimal attack surface (~5MB base), fast boot, apk package manager is simple and secure.

### Why Unprivileged Containers?

Security by design - container escapes affect unprivileged user, not root. This is the default and should never be changed without strong justification.

### The Augment's Role

Acts as intelligent orchestrator - monitors all components, processes natural language commands, and can trigger automated responses to events (file arrivals, system alerts, etc.).

### Service Communication

Services communicate via filesystem and logs rather than network sockets for simplicity and security. The Augment reads logs and can invoke other services as shell commands.

### Deployment Target

Designed for **Proxmox VE 7.0+** with LXC container support. Not compatible with Docker or other container runtimes without significant modifications.

### Testing Philosophy

All services have a `test` command for quick validation. Always test individual components before integration.

---

**For Mr. Magoo:** See `docs/SETUP.md` for step-by-step instructions with big friendly letters! 👓
