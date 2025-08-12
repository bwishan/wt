# Release Checklist for wt

## Pre-Release

- [ ] All tests pass locally (`python3 test_wt.py ./wt`)
- [ ] Version updated in `wt` script (`__version__ = "X.Y.Z"`)
- [ ] CHANGELOG.md updated with new features and fixes
- [ ] README.md updated if needed
- [ ] All changes committed and pushed to main branch

## Creating the Release

1. **Create and push the tag:**
   ```bash
   git tag v1.2.3
   git push origin v1.2.3
   ```

2. **Monitor the release workflow:**
   - Check GitHub Actions for successful test run
   - Verify build artifacts are created
   - Confirm release is published

3. **Update release notes:**
   - Edit the auto-generated release on GitHub
   - Add highlights and notable changes
   - Include installation instructions

## Post-Release

- [ ] Verify release downloads work
- [ ] Test installation process
- [ ] Update any external documentation
- [ ] Consider announcing release

## Hotfix Process

For urgent fixes:

1. Create hotfix branch from the release tag:
   ```bash
   git checkout v1.2.3
   git checkout -b hotfix/1.2.4
   ```

2. Make minimal fixes and update version
3. Create PR to main and release branch
4. After merge, tag the hotfix:
   ```bash
   git tag v1.2.4
   git push origin v1.2.4
   ```

## Version Numbering

- **Major** (X.0.0): Breaking changes, new architecture
- **Minor** (1.X.0): New features, backwards compatible
- **Patch** (1.2.X): Bug fixes, small improvements

## Rollback Plan

If a release has critical issues:

1. Mark GitHub release as pre-release
2. Add warning to release notes
3. Prepare hotfix or rollback as needed