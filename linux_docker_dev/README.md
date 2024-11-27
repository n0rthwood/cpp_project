# Remote Development Guide

This guide explains how to work with the remote development environment for this C++ project using Docker containers and SSH access.

## Development Workflow

1. **Connect to Remote Server**
   ```bash
   ssh joysort@10.10.50.10
   ```

2. **Start Docker Environment**
   ```bash
   cd /opt/workspace/cpp_project
   docker-compose up -d
   ```

3. **Connect to Docker Container**
   ```bash
   ssh -p 2222 developer@172.20.0.2
   # Password: developer
   ```

## Environment Details

### Docker Container
- Base Image: Ubuntu 22.04 LTS
- Development Tools:
  * GCC/G++ 11.4.0
  * CMake 3.22.1
  * Python 3.10
  * Build Essential
  * SSH Server
- Non-root user: 'developer'
- Working Directory: /workspace

### Volume Mounts
- Project files: `.:/workspace`
- SSH key: `~/.ssh/id_rsa.pub:/tmp/id_rsa.pub:ro`

### Network Configuration
- Container IP: 172.20.0.2
- SSH Port: 2222 (mapped to host)
- Network: Custom bridge network (172.20.0.0/16)

## Development Commands

Once connected to the Docker container via SSH, you can run development commands as if you were on a local Linux machine:

```bash
# Build the project
cd /workspace
./build.sh

# Run tests
./build/bin/test_core

# Test Python extension
python3 ./build/bin/test_joysort.py
```

## Troubleshooting

1. **Docker Container Not Starting**
   ```bash
   # Check container status
   docker ps -a
   # View container logs
   docker logs cpp_project_dev_container
   ```

2. **SSH Connection Issues**
   ```bash
   # Verify SSH service is running in container
   docker exec cpp_project_dev_container service ssh status
   # Check SSH key permissions
   docker exec cpp_project_dev_container ls -la /home/developer/.ssh
   ```

3. **Build Issues**
   - Ensure all dependencies are installed in the container
   - Check if vcpkg is properly initialized
   - Verify file permissions in mounted volumes
