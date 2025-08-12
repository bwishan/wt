# Homebrew Distribution for wt

This document explains how to set up and maintain the Homebrew distribution for the wt git worktree manager.

## Quick Installation (for users)

Once published to Homebrew:

```bash
# Install from official Homebrew
brew install wt

# Or install from our tap
brew tap bwishan/wt
brew install wt
```

## Setting Up the Homebrew Tap

### 1. Create Tap Repository

Create a new GitHub repository named `homebrew-wt` (following Homebrew naming convention):

```bash
# The repository should be named: homebrew-wt
# GitHub URL will be: https://github.com/bwishan/homebrew-wt
```

### 2. Initialize Tap Repository

```bash
# Clone the new repository
git clone https://github.com/bwishan/homebrew-wt.git
cd homebrew-wt

# Create Formula directory
mkdir Formula

# Copy our formula
cp ../wt/Formula/wt.rb Formula/

# Create initial commit
git add Formula/wt.rb
git commit -m "Add wt formula v0.2.0"
git push origin main
```

### 3. Test the Tap

```bash
# Add your tap locally
brew tap bwishan/wt

# Install from your tap
brew install bwishan/wt/wt

# Test the installation
wt --version
```

## Updating the Formula

### Automated Updates (Recommended)

The release workflow automatically generates updated Homebrew formulas. After each release:

1. Download the updated formula from GitHub Actions artifacts
2. Copy it to your `homebrew-wt` repository
3. Commit and push the changes

### Manual Updates

Use the provided script to update the formula:

```bash
# Update formula for new version
./scripts/update-homebrew.sh 0.2.1

# Review changes
git diff Formula/wt.rb

# Test the formula
brew install --build-from-source Formula/wt.rb

# Commit if everything works
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

## Publishing to Official Homebrew

To get wt into the official Homebrew repository:

### 1. Requirements Check
- [ ] Tool is stable and widely used
- [ ] Has been in a tap for some time
- [ ] No trademark issues with the name "wt"
- [ ] Follows Homebrew guidelines

### 2. Submit to homebrew-core

```bash
# Fork homebrew-core
# Add the formula to Formula/wt.rb
# Submit a pull request

# The PR should include:
# - Our tested formula
# - Explanation of what wt does
# - Why it belongs in homebrew-core
```

### 3. Maintenance

Once in homebrew-core:
- Updates go through PRs to homebrew-core
- Community can help maintain the formula
- Automated tools may help with updates

## GitHub Actions Integration

Our release workflow automatically:

1. **Calculates SHA256** for the release tarball
2. **Generates formula** with correct version and checksum
3. **Creates artifacts** containing the updated formula
4. **Uploads to release** for easy access

To use the generated formula:

1. Go to the GitHub release page
2. Download the `homebrew-formula` artifact
3. Extract `wt.rb` 
4. Copy to your tap repository
5. Commit and push

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