# Remote Development Guide

This guide explains how to work with the remote development environment for this project.

## Configuration

The remote development configuration is stored in `.dev_config.yaml`:
- Remote server: joysort@10.10.50.10
- Workspace path: /opt/workspace/
- Repository: git@github.com:n0rthwood/cpp_project.git

## Quick Start

1. Clone the repository:
```bash
git clone git@github.com:n0rthwood/cpp_project.git
cd cpp_project
```

2. Use the remote development script:
```bash
# Sync local files to remote
./remote_dev.sh sync

# Build on remote
./remote_dev.sh build

# Run tests on remote
./remote_dev.sh test

# Test Python extension
./remote_dev.sh python

# Or do all of the above
./remote_dev.sh all
```

## Development Workflow

1. Make changes locally
2. Commit and push to GitHub
3. Sync to remote: `./remote_dev.sh sync`
4. Build and test: `./remote_dev.sh build && ./remote_dev.sh test`
5. Test Python extension: `./remote_dev.sh python`

## Troubleshooting

If you encounter issues:
1. Check SSH connection: `ssh joysort@10.10.50.10`
2. Verify remote workspace exists: `ssh joysort@10.10.50.10 "ls -la /opt/workspace/"`
3. Check build logs: `ssh joysort@10.10.50.10 "cat /opt/workspace/cpp_project/build/CMakeFiles/CMakeError.log"`
