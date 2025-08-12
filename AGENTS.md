# Agent Instructions for wt Project

## Quick Reference
For detailed project specifications, command structure, and feature descriptions, see [README.md](./README.md).

## Project Infrastructure & Deployment

### Platform & Hosting
- **Repository**: Hosted on GitHub
- **CI/CD**: Fully implemented with GitHub Actions
- **Distribution**: Automated release system with Homebrew formula generation
- **Target Platforms**: macOS, Linux, Windows WSL

### Testing Strategy
- Use `test_wt.py` for testing
- Tests should run in GitHub Actions environment
- Ensure cross-platform compatibility when writing tests
- Test both successful operations and error conditions

## Development Guidance for Agents

### Code Architecture Decisions
- **Language**: Python (existing codebase)
- **Dependencies**: Keep minimal - avoid heavy dependencies
- **Configuration**: Use INI format for `.wtconfig` files
- **Error Handling**: Use clear, actionable error messages with appropriate symbols (✓, ✗, ⚠)

### CLI Design Principles
When implementing new features:
1. **Follow git patterns**: Commands should feel familiar to git users
2. **Consistent output**: Use table formatting with proper column alignment
3. **Color support**: Implement with environment variable respect (`NO_COLOR`, `FORCE_COLOR`, `WT_COLOR`)
4. **Interactive fallbacks**: Provide prompts when required arguments are missing
5. **Smart defaults**: Use sensible defaults (e.g., `origin/main` as base branch)

### Implementation Priorities
When choosing between features or approaches:
1. **Core functionality first**: Focus on `list`, `new`, `rm` commands
2. **Scriptability**: Ensure commands work well in scripts and automation
3. **Performance**: Prioritize fast execution over rich features
4. **Simplicity**: Choose simpler solutions that maintain the "minimal" philosophy

### Future Distribution Considerations
- Code should be packageable for Homebrew distribution
- Consider how features will work in different installation contexts
- Maintain compatibility with standard Python packaging tools
- Plan for eventual shell completion scripts

### Testing Guidelines
- Test both interactive and non-interactive modes
- Verify color output works correctly across environments
- Test configuration file parsing and defaults
- Ensure proper cleanup of worktrees in test scenarios

### When Adding Dependencies
- Prefer Python standard library when possible
- Any new dependencies should be justified for core functionality
- Consider impact on future Homebrew packaging
- Document any new requirements clearly

## Release Management for Agents

**IMPORTANT**: This project has a fully automated release system. Agents can create and publish releases by following these exact steps.

### Release Workflow Overview
The release system uses semantic versioning and automated GitHub Actions workflows. When agents create releases, they should follow this process:

### Step-by-Step Release Instructions for Agents

#### 0. Ensure Latest Changes are on 'develop' and no other files have been changed.
```bash
git checkout develop
git status
git pull origin develop
```

#### 1. Pre-Release Validation
Before creating any release, agents MUST:
```bash
# Ensure all tests pass
python3 test_wt.py ./wt

# Check current version
./scripts/version.sh current
```

#### 2. Version Bumping
Use the version management script to bump version appropriately:
```bash
# For bug fixes (0.2.0 → 0.2.1)
./scripts/version.sh bump patch

# For new features (0.2.0 → 0.3.0)  
./scripts/version.sh bump minor

# For breaking changes (0.2.0 → 1.0.0)
./scripts/version.sh bump major
```

**What this does automatically:**
- Updates `__version__` in the `wt` script
- Updates `CHANGELOG.md` with new version entry and date
- Creates a git commit with the version bump

#### 3. Create Git Tag
```bash
./scripts/version.sh tag
```

**What this does:**
- Creates an annotated git tag (e.g., `v0.2.1`)
- Validates working directory is clean
- Prevents duplicate tags

#### 4. Trigger Automated Release
```bash
# Push the tag to trigger GitHub Actions release workflow
git push origin v[VERSION]  # e.g., git push origin v0.2.1
```

**What happens automatically:**
- GitHub Actions runs full test suite on multiple platforms
- Build script (`build.sh`) creates release assets:
  - Standalone `wt` executable
  - Universal tarball (`wt-X.Y.Z-universal.tar.gz`)
  - Universal zip for Windows users
  - SHA256 checksums (`checksums.txt`)
- Creates GitHub release with auto-generated notes
- Generates Homebrew formula as artifact

### Release Types and When to Use Them

- **Patch Release** (`bump patch`): Bug fixes, security patches, minor improvements
- **Minor Release** (`bump minor`): New features, enhancements, backwards-compatible changes
- **Major Release** (`bump major`): Breaking changes, major architecture changes

### Agent Release Command Examples

When asked to create a release, agents should determine the appropriate type:

```bash
# Example: Bug fix release
./scripts/version.sh bump patch
./scripts/version.sh tag
git push origin v$(./scripts/version.sh current)

# Example: New feature release  
./scripts/version.sh bump minor
./scripts/version.sh tag
git push origin v$(./scripts/version.sh current)
```

### Verification Steps
After triggering a release, agents should:
1. Monitor GitHub Actions workflow completion
2. Verify release appears at: `https://github.com/[USERNAME]/wt/releases`
3. Check that all assets are present in the release
4. Confirm checksums file is included

### Emergency Procedures
If a release fails or has critical issues:
1. **DO NOT** delete the git tag immediately
2. Mark the GitHub release as "pre-release" if possible
3. Create a hotfix branch for immediate fixes
4. Use patch version bump for hotfix releases

### Build System Details
- **Build Script**: `build.sh` - Creates all release assets with validation
- **Test Integration**: Full test suite runs before any release
- **Multi-platform**: Automated testing on Ubuntu, macOS, Windows
- **Checksums**: SHA256 hashes generated for all binary assets
- **Packaging**: Multiple formats (tarball, zip) for different platforms

### Important Files for Releases
- `scripts/version.sh` - Version management utility
- `build.sh` - Production build script
- `.github/workflows/release.yml` - Release automation
- `.github/workflows/test.yml` - Testing pipeline
- `CHANGELOG.md` - Release notes and history
- `.github/RELEASE_TEMPLATE.md` - Release checklist

### Agent Success Criteria
A successful release by an agent includes:
- ✅ Tests pass before release creation
- ✅ Version bump committed and tagged
- ✅ GitHub Actions workflow completes successfully
- ✅ Release artifacts are generated and accessible
- ✅ Release appears on GitHub releases page
- ✅ Checksums match expected values
- ✅ Homebrew tap updated (see post-release steps below)

### Post-Release: Homebrew Tap Updates

After successfully creating a GitHub release, agents should update the Homebrew tap:

```bash
# Update the Homebrew tap formula
./scripts/update-tap.sh [VERSION]

# Example for version 0.2.1
./scripts/update-tap.sh 0.2.1
```

**What this does:**
- Downloads the new release tarball
- Calculates SHA256 checksum
- Updates the Homebrew formula in ../homebrew-wt repository
- Commits and pushes changes to the tap repository

**Prerequisites:**
- The homebrew-wt repository must be cloned in the parent directory
- GitHub CLI must be authenticated
- The release must exist on GitHub before updating the tap

### Troubleshooting Common Issues
- **Version mismatch**: Ensure git tag version matches script version
- **Test failures**: Fix failing tests before attempting release
- **Build failures**: Check `build.sh` output for specific errors
- **Permission issues**: Verify GitHub token has release permissions
- **Tap update failures**: Ensure homebrew-wt repository is accessible and up to date