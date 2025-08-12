#!/usr/bin/env bash
# Version management script for wt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WT_SCRIPT="$PROJECT_DIR/wt"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $0 <command> [arguments]

Commands:
    current                 Show current version
    bump <major|minor|patch> Bump version and create commit
    check                   Check if version is consistent
    tag                     Create git tag for current version

Examples:
    $0 current              # Show: 0.2.0
    $0 bump patch           # 0.2.0 -> 0.2.1
    $0 bump minor           # 0.2.0 -> 0.3.0
    $0 bump major           # 0.2.0 -> 1.0.0
    $0 tag                  # Create git tag v0.2.0
EOF
}

get_current_version() {
    grep '__version__ = ' "$WT_SCRIPT" | sed 's/__version__ = "\(.*\)"/\1/'
}

bump_version() {
    local bump_type="$1"
    local current_version
    current_version=$(get_current_version)
    
    # Parse current version
    if [[ ! $current_version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        echo -e "${RED}Error: Invalid version format: $current_version${NC}" >&2
        exit 1
    fi
    
    local major="${BASH_REMATCH[1]}"
    local minor="${BASH_REMATCH[2]}"
    local patch="${BASH_REMATCH[3]}"
    
    # Calculate new version
    case "$bump_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            echo -e "${RED}Error: Invalid bump type: $bump_type${NC}" >&2
            echo "Use: major, minor, or patch" >&2
            exit 1
            ;;
    esac
    
    local new_version="$major.$minor.$patch"
    
    echo -e "${YELLOW}Bumping version: $current_version -> $new_version${NC}"
    
    # Update version in script
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/__version__ = \".*\"/__version__ = \"$new_version\"/" "$WT_SCRIPT"
    else
        # Linux
        sed -i "s/__version__ = \".*\"/__version__ = \"$new_version\"/" "$WT_SCRIPT"
    fi
    
    # Update CHANGELOG.md if it exists
    if [ -f "$PROJECT_DIR/CHANGELOG.md" ]; then
        local date=$(date +%Y-%m-%d)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/## \[Unreleased\]/## [Unreleased]\n\n## [$new_version] - $date/" "$PROJECT_DIR/CHANGELOG.md"
        else
            sed -i "s/## \[Unreleased\]/## [Unreleased]\n\n## [$new_version] - $date/" "$PROJECT_DIR/CHANGELOG.md"
        fi
        echo -e "${GREEN}Updated CHANGELOG.md${NC}"
    fi
    
    # Create commit
    git add "$WT_SCRIPT" "$PROJECT_DIR/CHANGELOG.md" 2>/dev/null || git add "$WT_SCRIPT"
    git commit -m "Bump version to $new_version"
    
    echo -e "${GREEN}Version bumped to $new_version and committed${NC}"
    echo -e "${YELLOW}To create a release, run: $0 tag${NC}"
}

check_version() {
    local current_version
    current_version=$(get_current_version)
    
    echo "Current version: $current_version"
    
    # Check if there's a git tag for this version
    if git tag -l | grep -q "^v$current_version$"; then
        echo -e "${GREEN}✓ Git tag v$current_version exists${NC}"
    else
        echo -e "${YELLOW}⚠ No git tag found for v$current_version${NC}"
    fi
    
    # Check if working directory is clean
    if git diff-index --quiet HEAD --; then
        echo -e "${GREEN}✓ Working directory is clean${NC}"
    else
        echo -e "${YELLOW}⚠ Working directory has uncommitted changes${NC}"
    fi
}

create_tag() {
    local current_version
    current_version=$(get_current_version)
    local tag_name="v$current_version"
    
    # Check if tag already exists
    if git tag -l | grep -q "^$tag_name$"; then
        echo -e "${RED}Error: Tag $tag_name already exists${NC}" >&2
        exit 1
    fi
    
    # Check if working directory is clean
    if ! git diff-index --quiet HEAD --; then
        echo -e "${RED}Error: Working directory has uncommitted changes${NC}" >&2
        exit 1
    fi
    
    echo -e "${YELLOW}Creating tag $tag_name${NC}"
    git tag -a "$tag_name" -m "Release version $current_version"
    
    echo -e "${GREEN}Created tag $tag_name${NC}"
    echo -e "${YELLOW}To push the tag and trigger release: git push origin $tag_name${NC}"
}

main() {
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi
    
    case "$1" in
        current)
            get_current_version
            ;;
        bump)
            if [ $# -ne 2 ]; then
                echo -e "${RED}Error: bump requires a bump type${NC}" >&2
                usage
                exit 1
            fi
            bump_version "$2"
            ;;
        check)
            check_version
            ;;
        tag)
            create_tag
            ;;
        *)
            echo -e "${RED}Error: Unknown command: $1${NC}" >&2
            usage
            exit 1
            ;;
    esac
}

main "$@"