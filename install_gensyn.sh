#!/bin/bash

# ==========================================
# Gensyn RL Swarm - One-Click Installer
# Created for: getcakedieyoungx
# ==========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 1. ASCII Art
print_ascii() {
    clear
    echo -e "${PURPLE}"
    echo "   __ _  ___| |_ ___ __ _| | _____  __| (_) ___ _   _  ___  _   _ _ __   __ _ "
    echo "  / _\` |/ _ \ __/ __/ _\` | |/ / _ \/ _\` | |/ _ \ | | |/ _ \| | | | '_ \ / _\` |"
    echo " | (_| |  __/ || (_| (_| |   <  __/ (_| | |  __/ |_| | (_) | |_| | | | | (_| |"
    echo "  \__, |\___|\__\___\__,_|_|\_\___|\__,_|_|\___|\__, |\___/ \__,_|_| |_|\__, |"
    echo "  |___/                                         |___/                   |___/ "
    echo "          getcakedieyoungx - Gensyn Node Installer"
    echo -e "${NC}"
    echo -e "${CYAN}Starting automated setup...${NC}"
    sleep 2
}

# 2. Helper Functions
print_step() {
    echo -e "${BLUE}[STEP] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

print_warning() {
    echo -e "${RED}[WARNING] $1${NC}"
}

# 3. Main Installation Logic
install_dependencies() {
    print_step "Updating system packages..."
    sudo apt update && sudo apt upgrade -y

    print_step "Installing general utilities..."
    sudo apt install screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y

    print_step "Installing Python..."
    sudo apt install python3 python3-pip python3-venv python3-dev -y

    print_step "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
    sudo apt install -y nodejs
    
    print_step "Installing Yarn..."
    npm install -g yarn
    
    # Verify installations
    node_version=$(node -v)
    yarn_version=$(yarn -v)
    print_success "Node: $node_version | Yarn: $yarn_version"
}

setup_repo() {
    print_step "Cloning Gensyn RL Swarm repository..."
    if [ -d "rl-swarm" ]; then
        print_warning "Directory 'rl-swarm' already exists. Skipping clone."
    else
        git clone https://github.com/gensyn-ai/rl-swarm/
    fi
}

setup_tunnel() {
    print_step "Setting up LocalTunnel for remote access..."
    sudo npm install -g localtunnel

    # Get Public IP for Password
    PUBLIC_IP=$(curl -s https://loca.lt/mytunnelpassword)
    
    print_step "Starting Tunnel in background..."
    # Start localtunnel on port 3000 and log output to a temp file to capture URL
    nohup lt --port 3000 > tunnel.log 2>&1 &
    TUNNEL_PID=$!
    
    # Wait a moment for tunnel to initialize
    sleep 5
    
    # Extract URL from log
    TUNNEL_URL=$(grep -o 'https://[^ ]*' tunnel.log | head -n 1)
    
    if [ -z "$TUNNEL_URL" ]; then
        print_warning "Could not retrieve Tunnel URL automatically. You may need to run 'lt --port 3000' manually in another terminal."
    else
        echo -e "${GREEN}==================================================${NC}"
        echo -e "${GREEN} ACCESS YOUR NODE DASHBOARD HERE:${NC}"
        echo -e "${CYAN} URL:      ${TUNNEL_URL} ${NC}"
        echo -e "${CYAN} PASSWORD: ${PUBLIC_IP} ${NC}"
        echo -e "${GREEN}==================================================${NC}"
        echo -e "${PURPLE}IMPORTANT: Save this info! You will need it when the logs say 'Waiting for userData.json'${NC}"
        echo -e "${PURPLE}Press ENTER to acknowledge and continue to Swarm setup...${NC}"
        read
    fi
}

run_swarm() {
    print_step "Preparing Python Virtual Environment..."
    cd rl-swarm
    python3 -m venv .venv
    source .venv/bin/activate || . .venv/bin/activate

    print_step "Starting Gensyn RL Swarm..."
    echo -e "${RED}NOTE: You will be asked for your HuggingFace Token. Please have it ready.${NC}"
    echo -e "${RED}NOTE: If you have a 'swarm.pem' file, ensure it is in the 'rl-swarm' directory before this step.${NC}"
    
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN}           FINAL INSTRUCTIONS                     ${NC}"
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${CYAN}1. The Tunnel is running in the background. It won't close.${NC}"
    echo -e "${CYAN}2. Your Node logs will appear below.${NC}"
    echo -e "${PURPLE}3. TO EXIT SAFELY: Press 'CTRL + A' then 'D'.${NC}"
    echo -e "${PURPLE}   This detaches the screen but keeps the node running.${NC}"
    echo -e "${GREEN}==================================================${NC}"
    
    read -p "Press ENTER to launch the Swarm..."
    
    # Run the swarm script
    ./run_rl_swarm.sh
}

# 4. Execution Flow
print_ascii
install_dependencies
setup_repo
setup_tunnel
run_swarm
