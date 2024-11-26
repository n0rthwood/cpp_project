# Remote Development Guide

This guide explains how to work with the remote development environment for this project.

## Configuration

The remote development configuration is stored in `.dev_config.yaml`:
- Remote server: joysort@10.10.50.10
- Workspace path: /opt/workspace/
- Repository: git@github.com:n0rthwood/cpp_project.git

## Docker Development Environment

The project uses Docker for consistent development environments. The following files are provided:
- `Dockerfile` - Defines the development environment
- `docker_dev.sh` - Script to manage the Docker environment

### Quick Start with Docker

1. Build the Docker image:
```bash
./docker_dev.sh build
```

2. Start the development container:
```bash
./docker_dev.sh start
```

3. Enter the container:
```bash
./docker_dev.sh exec
```

4. Build and test inside the container:
```bash
./build.sh
```

### Docker Commands

- Build image: `./docker_dev.sh build`
- Start container: `./docker_dev.sh start`
- Stop container: `./docker_dev.sh stop`
- Restart container: `./docker_dev.sh restart`
- Execute command: `./docker_dev.sh exec [command]`
- Check status: `./docker_dev.sh status`

## Standard Development Workflow

1. Make changes locally
2. Commit and push to GitHub
3. Sync to remote: `./remote_dev.sh sync`
4. Enter Docker container: `./docker_dev.sh exec`
5. Build and test: `./build.sh`

## Troubleshooting

If you encounter issues:
1. Check SSH connection: `ssh joysort@10.10.50.10`
2. Verify Docker is running: `docker ps`
3. Check Docker logs: `docker logs cpp_project_dev_container`
4. Rebuild Docker image: `./docker_dev.sh build`
5. Check build logs in container: `./docker_dev.sh exec cat build/CMakeFiles/CMakeError.log`
