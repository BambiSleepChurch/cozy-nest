#!/bin/bash
#
# 🏠 COZY NEST DEPLOYMENT SCRIPT
# Deploy the entire secure infrastructure step-by-step
#
# Usage: ./deploy-nest.sh
#

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_ID=100
CONTAINER_NAME="bambisleep-nest"
STORAGE="local-lvm"
MEMORY=2048
SWAP=512
CORES=2
DISK_SIZE=8
ROOT_PASSWORD="nyks=strix=rog=zzz=490=€"

echo ""
echo "=========================================="
echo "   🏠 COZY NEST DEPLOYMENT"
echo "=========================================="
echo ""

# Step 1: Check if Proxmox is available
echo -e "${BLUE}📋 STEP 1: Checking prerequisites...${NC}"
if ! command -v pct &> /dev/null; then
    echo -e "${RED}❌ ERROR: This script must run on a Proxmox VE host!${NC}"
    echo "   Please run this script on your Proxmox server."
    exit 1
fi
echo -e "${GREEN}✅ Proxmox VE detected${NC}"
echo ""

# Step 2: Find and download Alpine Linux template
echo -e "${BLUE}📋 STEP 2: Finding Alpine Linux template...${NC}"

# Update template list
pveam update

# Try to find an already downloaded template first
DOWNLOADED=$(pveam list local 2>/dev/null | grep -i alpine | grep "amd64\|x86_64" | head -1 | awk '{print $1}')

if [ -n "$DOWNLOADED" ]; then
    echo -e "${GREEN}✅ Found downloaded template: $DOWNLOADED${NC}"
    TEMPLATE="$DOWNLOADED"
else
    # List available Alpine templates
    echo "   Searching for Alpine templates..."
    TEMPLATE_NAME=$(pveam available | grep -i alpine | grep "amd64\|x86_64" | grep -E "default|standard" | head -1 | awk '{print $2}')
    
    if [ -z "$TEMPLATE_NAME" ]; then
        echo -e "${RED}❌ ERROR: No Alpine templates found!${NC}"
        echo ""
        echo "   Available templates:"
        pveam available | grep -i alpine | head -10
        echo ""
        echo "   Manual fix:"
        echo "   1. Find a template: pveam available | grep alpine"
        echo "   2. Download it: pveam download local <template-name>"
        echo "   Example: pveam download local alpine-3.22-default_20250617_amd64.tar.xz"
        exit 1
    fi
    
    echo "   Found template: $TEMPLATE_NAME"
    echo "   Downloading to local storage..."
    echo "   (This may take a moment...)"
    
    if pveam download local "$TEMPLATE_NAME"; then
        echo -e "${GREEN}✅ Template downloaded successfully${NC}"
        TEMPLATE="local:vztmpl/$TEMPLATE_NAME"
    else
        echo -e "${RED}❌ ERROR: Failed to download template${NC}"
        echo ""
        echo "   Try manually:"
        echo "   pveam download local $TEMPLATE_NAME"
        exit 1
    fi
fi

echo ""

# Step 3: Create the BambiSleep container
echo -e "${BLUE}📋 STEP 3: Creating BambiSleep security container...${NC}"
if pct status $CONTAINER_ID &> /dev/null; then
    echo -e "${YELLOW}⚠️  Container $CONTAINER_ID already exists${NC}"
    read -p "   Do you want to destroy it and recreate? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "   Stopping and removing existing container..."
        pct stop $CONTAINER_ID 2>/dev/null || true
        pct destroy $CONTAINER_ID
    else
        echo "   Using existing container..."
        CONTAINER_EXISTS=1
    fi
fi

if [ -z "$CONTAINER_EXISTS" ]; then
    echo "   Creating unprivileged Alpine Linux container..."
    echo "   Using template: $TEMPLATE"
    
    pct create $CONTAINER_ID "$TEMPLATE" \
        --hostname $CONTAINER_NAME \
        --memory $MEMORY \
        --swap $SWAP \
        --cores $CORES \
        --rootfs $STORAGE:$DISK_SIZE \
        --unprivileged 1 \
        --features nesting=1 \
        --net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp \
        --password "$ROOT_PASSWORD" \
        --onboot 1

    echo -e "${GREEN}✅ Container created (ID: $CONTAINER_ID)${NC}"
fi
echo ""

# Step 4: Start the container
echo -e "${BLUE}📋 STEP 4: Starting container...${NC}"
if ! pct status $CONTAINER_ID | grep -q "running"; then
    pct start $CONTAINER_ID
    sleep 5
fi
echo -e "${GREEN}✅ Container started${NC}"
echo ""

# Step 5: Install base packages
echo -e "${BLUE}📋 STEP 5: Installing base packages...${NC}"
pct exec $CONTAINER_ID -- ash -c "apk update && apk upgrade"
pct exec $CONTAINER_ID -- ash -c "apk add \
    bash \
    curl \
    wget \
    nano \
    htop \
    python3 \
    py3-pip \
    openssh \
    nmap \
    tcpdump \
    inotify-tools \
    nginx \
    supervisor \
    git"
echo -e "${GREEN}✅ Base packages installed${NC}"
echo ""

# Step 6: Create directory structure
echo -e "${BLUE}📋 STEP 6: Creating nest directory structure...${NC}"
pct exec $CONTAINER_ID -- ash -c "
mkdir -p /opt/nest/{services,dropbox/{incoming,processing,archive},logs,config}
chmod 755 /opt/nest
chmod 777 /opt/nest/dropbox/incoming
"
echo -e "${GREEN}✅ Directory structure created${NC}"
echo ""

# Step 7: Copy service files to container
echo -e "${BLUE}📋 STEP 7: Deploying services to container...${NC}"
if [ -d "../services" ]; then
    echo "   Copying services from host..."
    pct push $CONTAINER_ID ../services /opt/nest/services -r
    pct exec $CONTAINER_ID -- chmod +x /opt/nest/services/*/*.sh 2>/dev/null || true
    pct exec $CONTAINER_ID -- chmod +x /opt/nest/services/*/*.py 2>/dev/null || true
    echo -e "${GREEN}✅ Services deployed${NC}"
else
    echo -e "${YELLOW}⚠️  Services directory not found in expected location${NC}"
    echo "   Services must be copied manually to /opt/nest/services/"
fi
echo ""

# Summary
echo ""
echo "=========================================="
echo "   ✨ NEST DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "Container ID: $CONTAINER_ID"
echo "Container Name: $CONTAINER_NAME"
echo "Status: Running"
echo "Template Used: $TEMPLATE"
echo ""
echo "📝 NEXT STEPS:"
echo ""
echo "1. Connect to your nest:"
echo "   pct enter $CONTAINER_ID"
echo ""
echo "2. Verify structure:"
echo "   ls -la /opt/nest/"
echo ""
echo "3. Test augment service:"
echo "   python3 /opt/nest/services/augment/augment.py health"
echo ""
echo "4. View logs:"
echo "   tail -f /opt/nest/logs/*.log"
echo ""
echo "⚠️  SECURITY NOTE:"
echo "   This container is UNPRIVILEGED for maximum security."
echo "   AppArmor is ENABLED."
echo ""
echo "🎉 Your cozy nest is ready!"
echo ""
