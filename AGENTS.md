# Agent Instructions for wt Project

## Quick Reference
For detailed project specifications, command structure, and feature descriptions, see [README.md](./README.md).

## Project Infrastructure & Deployment

### Platform & Hosting
- **Repository**: Hosted on GitHub
- **CI/CD**: Tests run on GitHub Actions runners (to be implemented)
- **Distribution**: Will be published via Homebrew (not yet implemented)
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