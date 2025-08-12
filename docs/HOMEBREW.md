# Homebrew Distribution for wt

This document explains how to maintain the Homebrew distribution for the wt git worktree manager.

## Installation (for users)

wt is available through our official Homebrew tap:

```bash
# Add our tap and install
brew tap bwishan/wt
brew install wt

# Or install directly
brew install bwishan/wt/wt
```

## Tap Repository

- **Repository**: https://github.com/bwishan/homebrew-wt
- **Formula**: `Formula/wt.rb`
- **Status**: Live and functional

## Updating the Formula

Use the provided script to update the formula for new releases:

```bash
# Update formula for new version
./scripts/update-tap.sh 0.2.1

# This automatically:
# 1. Downloads the new release tarball
# 2. Calculates SHA256 checksum
# 3. Updates the formula in ../homebrew-wt repository
# 4. Commits and pushes changes
```

### Manual Process (if needed)

If the script doesn't work, you can manually update:

```bash
# Go to the tap repository
cd ../homebrew-wt

# Edit Formula/wt.rb with new version, URL, and SHA256
# Commit and push changes
git add Formula/wt.rb
git commit -m "Update wt formula to v0.2.1"
git push origin main
```

## Formula Structure

Our Homebrew formula (`Formula/wt.rb`) includes:

- **Description**: Clear description of what wt does
- **Homepage**: Link to the GitHub repository
- **URL**: Direct link to the release tarball
- **SHA256**: Checksum for verification
- **Dependencies**: Python 3.11 and Git
- **Installation**: Simple binary installation
- **Test**: Verification that the tool works

## Future: Official Homebrew Core

If wt becomes widely adopted, we may consider submitting to official Homebrew:

- Requires proof of widespread usage
- Must meet strict Homebrew core guidelines  
- Community review process
- Would allow `brew install wt` without adding tap

For now, our tap provides all the benefits with full control.

## Testing Formula Changes

Always test formula changes before publishing:

```bash
# Test installation from source
brew install --build-from-source Formula/wt.rb

# Test the installed tool
wt --version
wt list  # Should work in a git repository

# Test uninstallation
brew uninstall wt

# Test reinstallation
brew install bwishan/wt/wt
```

## Common Issues

### Permission Errors
- Ensure the `wt` script is executable in the tarball
- Check that the binary is properly installed to `bin/`

### Dependency Issues
- Python version compatibility
- Git availability on the system

### Checksum Mismatches
- Regenerate SHA256 if the release tarball changes
- Use `./scripts/update-homebrew.sh` to avoid manual errors

## Homebrew Guidelines

Follow Homebrew's guidelines:
- Formula should be simple and focused
- Dependencies should be minimal
- Tests should verify basic functionality
- No network access during installation
- Support for macOS and Linux

## Resources

- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Homebrew Acceptable Formulae](https://docs.brew.sh/Acceptable-Formulae)
- [Creating Taps](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)