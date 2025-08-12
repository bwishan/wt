#!/usr/bin/env python3
"""
test_wt.py - Comprehensive test suite for wt (Git Worktree Manager)

This script creates isolated test environments to verify all functionality
of the wt tool without affecting the user's working repository.
"""

import asyncio
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import List, Tuple, Optional
import json

class TestRunner:
    """Test runner that manages isolated test environments."""
    
    def __init__(self, wt_script_path: str):
        self.wt_script_path = Path(wt_script_path).resolve()
        self.test_count = 0
        self.passed_count = 0
        self.failed_tests = []
        
    def log(self, message: str, level: str = "INFO"):
        """Log test messages with consistent formatting."""
        prefix = {
            "INFO": "ℹ️",
            "PASS": "✅", 
            "FAIL": "❌",
            "WARN": "⚠️"
        }.get(level, "•")
        print(f"{prefix} {message}")
    
    async def run_wt_command(self, *args: str, cwd: str, input_text: str = None) -> Tuple[int, str, str]:
        """Run wt command in specified directory and return (returncode, stdout, stderr)."""
        cmd = [str(self.wt_script_path)] + list(args)
        
        try:
            proc = await asyncio.create_subprocess_exec(
                *cmd,
                cwd=cwd,
                stdin=asyncio.subprocess.PIPE if input_text else None,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await proc.communicate(
                input=input_text.encode() if input_text else None
            )
            
            return proc.returncode, stdout.decode(), stderr.decode()
        except Exception as e:
            return 1, "", f"Failed to run command: {e}"
    
    async def run_git_command(self, *args: str, cwd: str) -> Tuple[int, str, str]:
        """Run git command in specified directory."""
        try:
            proc = await asyncio.create_subprocess_exec(
                "git", *args,
                cwd=cwd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await proc.communicate()
            return proc.returncode, stdout.decode(), stderr.decode()
        except Exception as e:
            return 1, "", f"Failed to run git command: {e}"
    
    def create_test_repo(self) -> str:
        """Create a temporary git repository for testing."""
        test_dir = tempfile.mkdtemp(prefix="wt_test_")
        
        # Initialize git repo
        subprocess.run(["git", "init"], cwd=test_dir, check=True, capture_output=True)
        subprocess.run(["git", "config", "user.name", "Test User"], cwd=test_dir, check=True)
        subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=test_dir, check=True)
        
        # Create initial commit
        initial_file = Path(test_dir) / "README.md"
        initial_file.write_text("# Test Repository\n")
        subprocess.run(["git", "add", "README.md"], cwd=test_dir, check=True)
        subprocess.run(["git", "commit", "-m", "Initial commit"], cwd=test_dir, check=True)
        
        return test_dir
    
    def cleanup_test_repo(self, test_dir: str):
        """Clean up temporary test repository."""
        if Path(test_dir).exists():
            shutil.rmtree(test_dir, ignore_errors=True)
    
    async def setup_dirty_worktree(self, test_dir: str, worktree_name: str) -> str:
        """Create a worktree with uncommitted changes."""
        # Create worktree
        code, out, err = await self.run_wt_command("new", worktree_name, cwd=test_dir)
        if code != 0:
            raise Exception(f"Failed to create worktree: {err}")
        
        # Find worktree path - construct expected path based on wt naming convention
        worktree_path = os.path.join(test_dir, f"_wt/{worktree_name.replace('/', '-')}")
        
        # Verify the worktree directory exists
        if not Path(worktree_path).exists():
            raise Exception(f"Worktree directory not found at expected path: {worktree_path}")
        
        # Create uncommitted changes
        staged_file = Path(worktree_path) / "staged.txt"
        staged_file.write_text("staged content")
        await self.run_git_command("add", "staged.txt", cwd=worktree_path)
        
        unstaged_file = Path(worktree_path) / "unstaged.txt"
        unstaged_file.write_text("unstaged content")
        
        untracked_file = Path(worktree_path) / "untracked.txt"
        untracked_file.write_text("untracked content")
        
        return worktree_path
    
    async def setup_git_operation_in_progress(self, worktree_path: str, operation: str):
        """Simulate git operation in progress."""
        git_file = Path(worktree_path) / ".git"
        
        # In worktrees, .git is a file pointing to the actual git directory
        if git_file.is_file():
            git_content = git_file.read_text().strip()
            if git_content.startswith("gitdir: "):
                git_dir = Path(git_content[8:])  # Remove "gitdir: " prefix
            else:
                raise Exception(f"Invalid .git file format: {git_content}")
        else:
            git_dir = git_file
        
        if operation == "merge":
            merge_head = git_dir / "MERGE_HEAD"
            merge_head.write_text("1234567890abcdef\n")
        elif operation == "rebase":
            rebase_dir = git_dir / "rebase-merge"
            rebase_dir.mkdir()
            (rebase_dir / "head-name").write_text("refs/heads/feature\n")
        elif operation == "cherry-pick":
            cherry_pick_head = git_dir / "CHERRY_PICK_HEAD"
            cherry_pick_head.write_text("1234567890abcdef\n")
        elif operation == "revert":
            revert_head = git_dir / "REVERT_HEAD"
            revert_head.write_text("1234567890abcdef\n")
    
    async def test_safety_checks(self) -> bool:
        """Test safety check functionality."""
        self.log("Running safety check tests...")
        test_dir = None
        
        try:
            test_dir = self.create_test_repo()
            
            # Test 1: Uncommitted changes detection
            worktree_path = await self.setup_dirty_worktree(test_dir, "feat/safety-test")
            
            # Should fail due to uncommitted changes
            code, out, err = await self.run_wt_command("rm", "feat/safety-test", cwd=test_dir)
            if code != 1 or ("uncommitted changes" not in err and "uncommitted changes" not in out):
                self.log(f"FAIL: Safety check should block removal with uncommitted changes. Code: {code}, Out: {out}, Error: {err}", "FAIL")
                return False
            
            # Should succeed with --force
            code, out, err = await self.run_wt_command("rm", "feat/safety-test", "--force", "--yes", cwd=test_dir)
            if code != 0:
                self.log(f"FAIL: --force should bypass safety checks. Code: {code}, Error: {err}", "FAIL")
                return False
            
            # Test 2: Git operations in progress
            # Create a clean worktree first
            code, out, err = await self.run_wt_command("new", "feat/merge-test", cwd=test_dir)
            if code != 0:
                self.log(f"FAIL: Failed to create merge test worktree. Code: {code}, Error: {err}", "FAIL")
                return False
            
            worktree_path = os.path.join(test_dir, "_wt/feat-merge-test")
            if not Path(worktree_path).exists():
                self.log(f"FAIL: Merge test worktree not found at {worktree_path}", "FAIL")
                return False
                
            # Set up merge operation without uncommitted changes
            await self.setup_git_operation_in_progress(worktree_path, "merge")
            
            # Should fail due to merge in progress
            code, out, err = await self.run_wt_command("rm", "feat/merge-test", cwd=test_dir)
            if code != 1 or ("merge in progress" not in err and "merge in progress" not in out):
                self.log(f"FAIL: Safety check should detect merge in progress. Code: {code}, Out: {out}, Error: {err}", "FAIL")
                return False
            
            # Clean up merge state and remove with force
            git_file = Path(worktree_path) / ".git"
            if git_file.is_file():
                git_content = git_file.read_text().strip()
                if git_content.startswith("gitdir: "):
                    git_dir = Path(git_content[8:])
                    merge_head = git_dir / "MERGE_HEAD"
                    if merge_head.exists():
                        merge_head.unlink()
            
            code, out, err = await self.run_wt_command("rm", "feat/merge-test", "--force", "--yes", cwd=test_dir)
            if code != 0:
                self.log(f"FAIL: Should be able to remove after cleaning merge state. Code: {code}, Error: {err}", "FAIL")
                return False
            
            self.log("Safety check tests passed", "PASS")
            return True
            
        except Exception as e:
            self.log(f"FAIL: Safety check tests failed with exception: {e}", "FAIL")
            return False
        finally:
            if test_dir:
                self.cleanup_test_repo(test_dir)
    
    async def test_flag_behavior(self) -> bool:
        """Test --force and --yes flag behavior."""
        self.log("Running flag behavior tests...")
        test_dir = None
        
        try:
            test_dir = self.create_test_repo()
            
            # Test --yes flag with clean worktree
            code, out, err = await self.run_wt_command("new", "feat/clean-test", cwd=test_dir)
            if code != 0:
                self.log(f"FAIL: Failed to create test worktree. Code: {code}, Error: {err}", "FAIL")
                return False
            
            # Should succeed with --yes (no confirmation needed)
            code, out, err = await self.run_wt_command("rm", "feat/clean-test", "--yes", cwd=test_dir)
            if code != 0:
                self.log(f"FAIL: --yes should skip confirmation for clean worktree. Code: {code}, Error: {err}", "FAIL")
                return False
            
            # Test that --yes still respects safety checks
            worktree_path = await self.setup_dirty_worktree(test_dir, "feat/dirty-test")
            
            # Should fail even with --yes (safety checks still active)
            code, out, err = await self.run_wt_command("rm", "feat/dirty-test", "--yes", cwd=test_dir)
            if code != 1 or ("uncommitted changes" not in err and "uncommitted changes" not in out):
                self.log(f"FAIL: --yes should not bypass safety checks. Code: {code}, Out: {out}, Error: {err}", "FAIL")
                return False
            
            # Clean up
            code, out, err = await self.run_wt_command("rm", "feat/dirty-test", "--force", "--yes", cwd=test_dir)
            if code != 0:
                self.log(f"FAIL: Failed to clean up test worktree. Code: {code}, Error: {err}", "FAIL")
                return False
            
            self.log("Flag behavior tests passed", "PASS")
            return True
            
        except Exception as e:
            self.log(f"FAIL: Flag behavior tests failed with exception: {e}", "FAIL")
            return False
        finally:
            if test_dir:
                self.cleanup_test_repo(test_dir)
    
    async def test_path_handling(self) -> bool:
        """Test path handling from different working directories."""
        self.log("Running path handling tests...")
        test_dir = None
        
        try:
            test_dir = self.create_test_repo()
            
            # Create worktree
            code, out, err = await self.run_wt_command("new", "feat/path-test", cwd=test_dir)
            if code != 0:
                self.log(f"FAIL: Failed to create test worktree. Code: {code}, Error: {err}", "FAIL")
                return False
            
            # Test from subdirectory (if exists)
            subdir = Path(test_dir) / "subdir"
            subdir.mkdir(exist_ok=True)
            
            # Should work from subdirectory
            code, out, err = await self.run_wt_command("list", cwd=str(subdir))
            if code != 0:
                self.log(f"FAIL: Should work from subdirectory. Code: {code}, Error: {err}", "FAIL")
                return False
            
            # Should be able to remove from subdirectory
            code, out, err = await self.run_wt_command("rm", "feat/path-test", "--yes", cwd=str(subdir))
            if code != 0:
                self.log(f"FAIL: Should be able to remove from subdirectory. Code: {code}, Error: {err}", "FAIL")
                return False
            
            self.log("Path handling tests passed", "PASS")
            return True
            
        except Exception as e:
            self.log(f"FAIL: Path handling tests failed with exception: {e}", "FAIL")
            return False
        finally:
            if test_dir:
                self.cleanup_test_repo(test_dir)
    
    async def test_branch_matching(self) -> bool:
        """Test branch matching and selection logic."""
        self.log("Running branch matching tests...")
        test_dir = None
        
        try:
            test_dir = self.create_test_repo()
            
            # Create worktrees with similar names
            branches = ["test", "feat/test", "feature/test"]
            for branch in branches:
                code, out, err = await self.run_wt_command("new", branch, cwd=test_dir)
                if code != 0:
                    self.log(f"FAIL: Failed to create worktree {branch}. Code: {code}, Error: {err}", "FAIL")
                    return False
            
            # Test exact match priority
            code, out, err = await self.run_wt_command("rm", "test", "--yes", cwd=test_dir)
            if code != 0:
                self.log(f"FAIL: Exact match should work. Code: {code}, Error: {err}", "FAIL")
                return False
            
            # Test non-existent branch
            code, out, err = await self.run_wt_command("rm", "nonexistent", cwd=test_dir)
            if code != 1 or "not found" not in err:
                self.log(f"FAIL: Should report error for non-existent branch. Code: {code}, Error: {err}", "FAIL")
                return False
            
            # Clean up remaining worktrees
            for branch in ["feat/test", "feature/test"]:
                await self.run_wt_command("rm", branch, "--yes", cwd=test_dir)
            
            self.log("Branch matching tests passed", "PASS")
            return True
            
        except Exception as e:
            self.log(f"FAIL: Branch matching tests failed with exception: {e}", "FAIL")
            return False
        finally:
            if test_dir:
                self.cleanup_test_repo(test_dir)
    
    async def test_error_conditions(self) -> bool:
        """Test error handling and edge cases."""
        self.log("Running error condition tests...")
        test_dir = None
        
        try:
            test_dir = self.create_test_repo()
            
            # Test main worktree protection
            code, out, err = await self.run_wt_command("rm", "main", cwd=test_dir)
            # Should either not find "main" or protect main worktree
            if code == 0:
                self.log(f"FAIL: Should not be able to remove main worktree", "FAIL")
                return False
            
            # Test behavior outside git repo
            non_git_dir = tempfile.mkdtemp(prefix="wt_non_git_")
            try:
                code, out, err = await self.run_wt_command("list", cwd=non_git_dir)
                if code != 1 or "git repository" not in err:
                    self.log(f"FAIL: Should detect non-git directory. Code: {code}, Error: {err}", "FAIL")
                    return False
            finally:
                shutil.rmtree(non_git_dir, ignore_errors=True)
            
            self.log("Error condition tests passed", "PASS")
            return True
            
        except Exception as e:
            self.log(f"FAIL: Error condition tests failed with exception: {e}", "FAIL")
            return False
        finally:
            if test_dir:
                self.cleanup_test_repo(test_dir)
    
    async def run_all_tests(self) -> int:
        """Run all test categories and return exit code."""
        self.log("Starting wt test suite...")
        
        # Check that wt script exists and is executable
        if not self.wt_script_path.exists():
            self.log(f"FAIL: wt script not found at {self.wt_script_path}", "FAIL")
            return 1
        
        # Run test categories
        test_functions = [
            ("Safety Checks", self.test_safety_checks),
            ("Flag Behavior", self.test_flag_behavior),
            ("Path Handling", self.test_path_handling),
            ("Branch Matching", self.test_branch_matching),
            ("Error Conditions", self.test_error_conditions),
        ]
        
        for test_name, test_func in test_functions:
            self.test_count += 1
            self.log(f"Running {test_name} tests...")
            
            if await test_func():
                self.passed_count += 1
            else:
                self.failed_tests.append(test_name)
        
        # Report results
        self.log(f"Test Results: {self.passed_count}/{self.test_count} passed")
        
        if self.failed_tests:
            self.log(f"Failed tests: {', '.join(self.failed_tests)}", "FAIL")
            return 1
        else:
            self.log("All tests passed!", "PASS")
            return 0


async def main():
    """Main entry point for test script."""
    if len(sys.argv) != 2:
        print("Usage: test_wt.py <path_to_wt_script>")
        print("Example: test_wt.py ./wt")
        return 1
    
    wt_script_path = sys.argv[1]
    
    # Check git availability
    if shutil.which("git") is None:
        print("❌ git not found in PATH")
        return 1
    
    runner = TestRunner(wt_script_path)
    return await runner.run_all_tests()


if __name__ == "__main__":
    try:
        exit_code = asyncio.run(main())
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\nTests interrupted by user")
        sys.exit(130)
    except Exception as e:
        print(f"❌ Test suite failed with error: {e}")
        sys.exit(1)