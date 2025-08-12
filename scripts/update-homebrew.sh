#!/usr/bin/env bash
# Update Homebrew formula for new wt releases

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[HOMEBREW]${NC} $*"
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
Usage: $0 <version>

Update Homebrew formula for a new wt release.

Arguments:
    version     Version to update to (e.g., "0.2.1")

Examples:
    $0 0.2.1    # Update formula to version 0.2.1

This script will:
1. Download the release tarball
2. Calculate SHA256 checksum
3. Update the Formula/wt.rb file
4. Create a commit with the changes
EOF
}

update_formula() {
    local version="$1"
    local repo_owner="bwishan"  # Update this to match your GitHub username
    local repo_name="wt"
    
    log "Updating Homebrew formula for wt v$version"
    
    # Construct release URL
    local tarball_url="https://github.com/$repo_owner/$repo_name/releases/download/v$version/$repo_name-$version-universal.tar.gz"
    local formula_file="Formula/wt.rb"
    
    # Check if formula file exists
    if [ ! -f "$formula_file" ]; then
        error "Formula file not found: $formula_file"
        exit 1
    fi
    
    log "Downloading release tarball to calculate SHA256..."
    local sha256
    sha256=$(curl -sL "$tarball_url" | shasum -a 256 | cut -d' ' -f1)
    
    if [ -z "$sha256" ]; then
        error "Failed to calculate SHA256 for $tarball_url"
        exit 1
    fi
    
    log "SHA256: $sha256"
    
    # Update the formula file
    log "Updating formula file..."
    
    # Create a backup
    cp "$formula_file" "$formula_file.backup"
    
    # Update URL, SHA256, and version using sed
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS sed
        sed -i '' "s|url \".*\"|url \"$tarball_url\"|" "$formula_file"
        sed -i '' "s|sha256 \".*\"|sha256 \"$sha256\"|" "$formula_file"
        sed -i '' "s|version \".*\"|version \"$version\"|" "$formula_file"
        sed -i '' "s|assert_match \"wt [0-9.]*\"|assert_match \"wt $version\"|" "$formula_file"
    else
        # Linux sed
        sed -i "s|url \".*\"|url \"$tarball_url\"|" "$formula_file"
        sed -i "s|sha256 \".*\"|sha256 \"$sha256\"|" "$formula_file"
        sed -i "s|version \".*\"|version \"$version\"|" "$formula_file"
        sed -i "s|assert_match \"wt [0-9.]*\"|assert_match \"wt $version\"|" "$formula_file"
    fi
    
    # Show the changes
    log "Updated formula file:"
    echo
    head -20 "$formula_file"
    echo
    
    # Clean up backup
    rm "$formula_file.backup"
    
    success "Homebrew formula updated for version $version"
    
    # Suggest next steps
    echo
    log "Next steps:"
    echo "1. Review the changes: git diff $formula_file"
    echo "2. Test the formula: brew install --build-from-source $formula_file"
    echo "3. Commit changes: git add $formula_file && git commit -m \"Update Homebrew formula to v$version\""
    echo "4. Submit to homebrew-core or your tap repository"
}

main() {
    if [ $# -ne 1 ]; then
        usage
        exit 1
    fi
    
    local version="$1"
    
    # Validate version format
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        error "Invalid version format: $version (expected: X.Y.Z)"
        exit 1
    fi
    
    update_formula "$version"
}

main "$@"