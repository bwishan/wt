#!/usr/bin/env bash
# Set up Homebrew tap repository for wt

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[HOMEBREW TAP]${NC} $*"
}

success() {
    echo -e "${GREEN}✓${NC} $*"
}

error() {
    echo -e "${RED}✗${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

usage() {
    cat << EOF
Usage: $0 <github-username>

Set up a Homebrew tap repository for wt.

Arguments:
    github-username     Your GitHub username (e.g., "bwishan")

This script will guide you through:
1. Creating the homebrew-wt repository structure
2. Setting up the initial formula
3. Testing the tap locally

Prerequisites:
- GitHub CLI (gh) installed and authenticated
- Homebrew installed
- Formula/wt.rb exists in current directory

Example:
    $0 bwishan
EOF
}

setup_tap() {
    local username="$1"
    local repo_name="homebrew-wt"
    local current_dir=$(pwd)
    
    log "Setting up Homebrew tap for user: $username"
    
    # Check if Formula/wt.rb exists
    if [ ! -f "Formula/wt.rb" ]; then
        error "Formula/wt.rb not found in current directory"
        error "Make sure you're running this from the wt project root"
        exit 1
    fi
    
    # Create temporary directory for tap setup
    local temp_dir=$(mktemp -d)
    local tap_dir="$temp_dir/$repo_name"
    
    log "Creating tap repository structure in $tap_dir"
    
    # Initialize the tap repository
    mkdir -p "$tap_dir/Formula"
    cd "$tap_dir"
    
    # Initialize git repository
    git init
    git config user.name "$(git config --global user.name)"
    git config user.email "$(git config --global user.email)"
    
    # Copy formula
    cp "$current_dir/Formula/wt.rb" "Formula/"
    
    # Create README
    cat > README.md << EOF
# Homebrew Tap for wt

This is the Homebrew tap for [wt](https://github.com/$username/wt), a minimalist git worktree manager.

## Installation

\`\`\`bash
brew tap $username/wt
brew install wt
\`\`\`

## Updating

The formula is automatically updated with each new release of wt.

## Formula

- **wt**: Git Worktree Manager - A minimalist CLI for managing git worktrees

## Contributing

This tap is automatically maintained. Formula updates come from the main wt repository releases.
EOF
    
    # Create initial commit
    git add .
    git commit -m "Initial commit: Add wt formula v$(grep 'version' Formula/wt.rb | sed 's/.*"\(.*\)".*/\1/')"
    
    success "Tap repository structure created"
    
    # Instructions for creating GitHub repository
    echo
    log "Next steps to publish your tap:"
    echo
    echo "1. Create the GitHub repository:"
    echo "   gh repo create $repo_name --public --description 'Homebrew tap for wt git worktree manager'"
    echo
    echo "2. Push the tap to GitHub:"
    echo "   cd $tap_dir"
    echo "   git branch -M main"
    echo "   git remote add origin https://github.com/$username/$repo_name.git"
    echo "   git push -u origin main"
    echo
    echo "3. Test your tap:"
    echo "   brew tap $username/wt"
    echo "   brew install $username/wt/wt"
    echo "   wt --version"
    echo
    echo "4. Clean up test installation:"
    echo "   brew uninstall wt"
    echo "   brew untap $username/wt"
    echo
    
    warn "Tap directory created at: $tap_dir"
    warn "Remember to clean up the temporary directory when done"
    
    # Offer to create the repo automatically
    echo
    read -p "Create GitHub repository now? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Creating GitHub repository..."
        
        if command -v gh &> /dev/null; then
            gh repo create "$repo_name" --public --description "Homebrew tap for wt git worktree manager"
            git branch -M main
            git remote add origin "https://github.com/$username/$repo_name.git"
            git push -u origin main
            
            success "GitHub repository created and pushed!"
            success "Your tap is now available at: https://github.com/$username/$repo_name"
        else
            error "GitHub CLI (gh) not found. Please create the repository manually."
        fi
    fi
    
    cd "$current_dir"
}

main() {
    if [ $# -ne 1 ]; then
        usage
        exit 1
    fi
    
    local username="$1"
    
    # Validate username format
    if [[ ! $username =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "Invalid GitHub username format: $username"
        exit 1
    fi
    
    setup_tap "$username"
}

main "$@"