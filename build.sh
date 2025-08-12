#!/usr/bin/env bash
# Build script for wt production releases
# Creates distribution-ready assets with checksums and packaging

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/dist"
SCRIPT_NAME="wt"
VERSION=$(grep '__version__ = ' "$SCRIPT_DIR/$SCRIPT_NAME" | sed 's/__version__ = "\(.*\)"/\1/')

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[BUILD]${NC} $*"
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

# Check dependencies
check_dependencies() {
    log "Checking build dependencies..."
    
    local missing=()
    
    if ! command -v python3 &> /dev/null; then
        missing+=("python3")
    fi
    
    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing required dependencies: ${missing[*]}"
        exit 1
    fi
    
    success "All dependencies found"
}

# Validate version format
validate_version() {
    log "Validating version: $VERSION"
    
    if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        error "Invalid version format: $VERSION (expected: X.Y.Z)"
        exit 1
    fi
    
    success "Version format valid: $VERSION"
}

# Run tests before building
run_tests() {
    log "Running test suite..."
    
    if ! python3 "$SCRIPT_DIR/test_wt.py" "$SCRIPT_DIR/$SCRIPT_NAME"; then
        error "Tests failed - aborting build"
        exit 1
    fi
    
    success "All tests passed"
}

# Clean and create build directory
prepare_build_dir() {
    log "Preparing build directory..."
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    
    mkdir -p "$BUILD_DIR"
    success "Build directory ready: $BUILD_DIR"
}

# Create standalone executable
create_standalone() {
    log "Creating standalone executable..."
    
    local output_file="$BUILD_DIR/$SCRIPT_NAME"
    
    # Copy the script and make it executable
    cp "$SCRIPT_DIR/$SCRIPT_NAME" "$output_file"
    chmod +x "$output_file"
    
    # Verify the standalone script works
    if ! "$output_file" --version &> /dev/null; then
        error "Standalone script validation failed"
        exit 1
    fi
    
    success "Standalone executable created: $output_file"
}

# Create platform-specific packages
create_packages() {
    log "Creating platform-specific packages..."
    
    # Universal package (just the script)
    local universal_dir="$BUILD_DIR/wt-$VERSION-universal"
    mkdir -p "$universal_dir"
    cp "$BUILD_DIR/$SCRIPT_NAME" "$universal_dir/"
    cp "$SCRIPT_DIR/README.md" "$universal_dir/"
    cp "$SCRIPT_DIR/install.sh" "$universal_dir/" 2>/dev/null || true
    
    # Create tarball
    (cd "$BUILD_DIR" && tar -czf "wt-$VERSION-universal.tar.gz" "wt-$VERSION-universal/")
    
    # Create zip for Windows users
    (cd "$BUILD_DIR" && zip -r "wt-$VERSION-universal.zip" "wt-$VERSION-universal/" > /dev/null)
    
    success "Universal packages created"
}

# Generate checksums
generate_checksums() {
    log "Generating checksums..."
    
    local checksum_file="$BUILD_DIR/checksums.txt"
    
    (cd "$BUILD_DIR" && {
        echo "# wt $VERSION - Release Checksums"
        echo "# Generated on $(date -u)"
        echo
        
        for file in *.tar.gz *.zip "$SCRIPT_NAME"; do
            if [ -f "$file" ]; then
                if command -v sha256sum &> /dev/null; then
                    sha256sum "$file"
                elif command -v shasum &> /dev/null; then
                    shasum -a 256 "$file"
                else
                    warn "No SHA256 utility found, skipping checksums"
                    return
                fi
            fi
        done
    }) > "$checksum_file"
    
    success "Checksums generated: $checksum_file"
}

# Create release notes template
create_release_notes() {
    log "Creating release notes template..."
    
    local notes_file="$BUILD_DIR/release-notes.md"
    
    cat > "$notes_file" << EOF
# wt $VERSION

## What's New

<!-- Add release highlights here -->

## Changes

<!-- Add detailed changes here -->

## Installation

### Direct Download

\`\`\`bash
# Download the universal package
curl -L -o wt-$VERSION-universal.tar.gz https://github.com/YOUR_USERNAME/wt/releases/download/v$VERSION/wt-$VERSION-universal.tar.gz

# Extract and install
tar -xzf wt-$VERSION-universal.tar.gz
cd wt-$VERSION-universal
chmod +x wt
sudo mv wt /usr/local/bin/
\`\`\`

### Using install script

\`\`\`bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/wt/main/install.sh | sh
\`\`\`

## Verification

Verify the download with checksums:

\`\`\`bash
# Check SHA256 (checksums available in release assets)
sha256sum wt-$VERSION-universal.tar.gz
\`\`\`

## Requirements

- Python 3.8 or later
- Git
- Unix-like environment (macOS, Linux, Windows WSL)

---

**Full Changelog**: https://github.com/YOUR_USERNAME/wt/compare/v[PREVIOUS_VERSION]...v$VERSION
EOF
    
    success "Release notes template created: $notes_file"
}

# Validate build artifacts
validate_build() {
    log "Validating build artifacts..."
    
    local artifacts=(
        "$BUILD_DIR/$SCRIPT_NAME"
        "$BUILD_DIR/wt-$VERSION-universal.tar.gz"
        "$BUILD_DIR/wt-$VERSION-universal.zip"
        "$BUILD_DIR/checksums.txt"
        "$BUILD_DIR/release-notes.md"
    )
    
    for artifact in "${artifacts[@]}"; do
        if [ ! -f "$artifact" ]; then
            error "Missing build artifact: $artifact"
            exit 1
        fi
    done
    
    # Test the packaged script
    local temp_dir=$(mktemp -d)
    tar -xzf "$BUILD_DIR/wt-$VERSION-universal.tar.gz" -C "$temp_dir"
    
    if ! "$temp_dir/wt-$VERSION-universal/$SCRIPT_NAME" --version &> /dev/null; then
        error "Packaged script validation failed"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    rm -rf "$temp_dir"
    success "All build artifacts validated"
}

# Display build summary
show_summary() {
    echo
    echo -e "${GREEN}🎉 Build completed successfully!${NC}"
    echo
    echo "Version: $VERSION"
    echo "Build directory: $BUILD_DIR"
    echo
    echo "Release artifacts:"
    ls -la "$BUILD_DIR"
    echo
    echo "To create a GitHub release:"
    echo "1. Push a tag: git tag v$VERSION && git push origin v$VERSION"
    echo "2. Upload the artifacts from $BUILD_DIR"
    echo "3. Use the release notes from $BUILD_DIR/release-notes.md"
}

# Main build process
main() {
    echo -e "${BLUE}🔨 Building wt v$VERSION${NC}"
    echo
    
    check_dependencies
    validate_version
    run_tests
    prepare_build_dir
    create_standalone
    create_packages
    generate_checksums
    create_release_notes
    validate_build
    show_summary
}

# Handle cleanup on exit
cleanup() {
    if [ $? -ne 0 ]; then
        error "Build failed"
        exit 1
    fi
}

trap cleanup EXIT

# Run main function
main "$@"