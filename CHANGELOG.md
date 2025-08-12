# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2025-08-12

### Added
- GitHub Actions CI/CD workflows for testing and releases
- Automated build system with `build.sh` script
- Release management and versioning system

### Changed
- Improved project documentation

### Fixed
- TBD

## [0.2.0] - 2025-08-12

### Added
- Core worktree management commands (`list`, `new`, `rm`, `sync`, `prune`)
- Interactive prompting and validation
- Smart branch matching with fuzzy search
- Color support with environment variable controls
- Configuration system with `.wtconfig` files
- Cross-platform support (macOS, Linux, Windows WSL)
- Comprehensive test suite with `test_wt.py`
- Safety checks for uncommitted changes and git operations in progress

### Changed
- Initial implementation of the wt CLI tool

### Security
- No known security issues

## [0.1.0] - Initial Development

### Added
- Project structure and basic framework
- Initial command parsing and git integration

---

## Release Links

- [Unreleased](https://github.com/YOUR_USERNAME/wt/compare/v0.2.0...HEAD)
- [0.2.0](https://github.com/YOUR_USERNAME/wt/releases/tag/v0.2.0)

<!-- Template for new releases:

## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing features

### Deprecated
- Features marked for removal

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security-related changes

-->