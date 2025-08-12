#!/bin/bash
set -e

# Colors for output - only enable if stdout is a terminal
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Get the directory where this script is located (tools/wt)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WT_DIR="$SCRIPT_DIR"
WT_SCRIPT="$WT_DIR/wt"

echo -e "${BLUE}WT Tool PATH Installation Script${NC}"
echo "================================="
echo ""

# Check if WT script exists
if [ ! -f "$WT_SCRIPT" ]; then
    echo -e "${RED}Error: WT script not found at $WT_SCRIPT${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found WT script at: $WT_SCRIPT"

# Make WT script executable
if [ ! -x "$WT_SCRIPT" ]; then
    echo -e "${YELLOW}→${NC} Making WT script executable..."
    chmod +x "$WT_SCRIPT"
    echo -e "${GREEN}✓${NC} WT script is now executable"
else
    echo -e "${GREEN}✓${NC} WT script is already executable"
fi

# Detect user's shell
USER_SHELL=$(basename "$SHELL")
echo -e "${GREEN}✓${NC} Detected shell: $USER_SHELL"

# Determine config file to modify
case "$USER_SHELL" in
    "zsh")
        CONFIG_FILE="$HOME/.zshrc"
        ;;
    "bash")
        # Check which bash config file exists
        if [ -f "$HOME/.bash_profile" ]; then
            CONFIG_FILE="$HOME/.bash_profile"
        else
            CONFIG_FILE="$HOME/.bashrc"
        fi
        ;;
    "fish")
        CONFIG_FILE="$HOME/.config/fish/config.fish"
        ;;
    *)
        echo -e "${YELLOW}Warning: Unknown shell '$USER_SHELL', defaulting to ~/.profile${NC}"
        CONFIG_FILE="$HOME/.profile"
        ;;
esac

echo -e "${GREEN}✓${NC} Will modify: $CONFIG_FILE"

# Create config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}→${NC} Creating $CONFIG_FILE"
    touch "$CONFIG_FILE"
fi

# Check if WT directory is already in PATH
PATH_ENTRY="export PATH=\"$WT_DIR:\$PATH\""
WT_COMMENT="# Added by WT tool installer"

if grep -q "$WT_DIR" "$CONFIG_FILE" 2>/dev/null; then
    echo -e "${YELLOW}!${NC} WT directory already appears to be in PATH in $CONFIG_FILE"
    echo "Skipping PATH modification."
else
    # Backup config file
    BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}→${NC} Creating backup: $BACKUP_FILE"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    
    # Add WT to PATH
    echo -e "${YELLOW}→${NC} Adding WT directory to PATH in $CONFIG_FILE"
    echo "" >> "$CONFIG_FILE"
    echo "$WT_COMMENT" >> "$CONFIG_FILE"
    echo "$PATH_ENTRY" >> "$CONFIG_FILE"
    echo -e "${GREEN}✓${NC} Added WT directory to PATH"
fi

# Test the installation
echo ""
echo -e "${BLUE}Testing installation...${NC}"

# Source the config file to test in current session
if [ -f "$CONFIG_FILE" ]; then
    # Export the PATH for this session
    export PATH="$WT_DIR:$PATH"
    
    # Test if wt command is available
    if command -v wt >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} WT command is available in PATH"
        
        # Test wt version
        if wt --version >/dev/null 2>&1; then
            WT_VERSION=$(wt --version 2>/dev/null || echo "unknown")
            echo -e "${GREEN}✓${NC} WT version: $WT_VERSION"
        else
            echo -e "${YELLOW}!${NC} WT command found but version check failed"
        fi
    else
        echo -e "${RED}✗${NC} WT command not found in PATH"
        echo "You may need to restart your terminal or run: source $CONFIG_FILE"
    fi
fi

# Provide next steps
echo ""
echo -e "${BLUE}Installation Summary:${NC}"
echo "===================="
echo -e "${GREEN}✓${NC} Made WT script executable"
echo -e "${GREEN}✓${NC} Added $WT_DIR to PATH in $CONFIG_FILE"
if [ -f "$BACKUP_FILE" ]; then
    echo -e "${GREEN}✓${NC} Created backup at $BACKUP_FILE"
fi
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Restart your terminal, or run: ${BLUE}source $CONFIG_FILE${NC}"
echo -e "2. Test the installation: ${BLUE}wt --version${NC}"
echo -e "3. View available commands: ${BLUE}wt --help${NC}"
echo ""
echo -e "${GREEN}Installation complete!${NC}"