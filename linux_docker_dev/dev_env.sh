#!/bin/bash

# Configuration
REMOTE_HOST="joysort@10.10.50.10"
DOCKER_HOST="developer@localhost"
DOCKER_PORT="2222"
PROJECT_DIR="/opt/workspace/cpp_project"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Error handling
set -e
trap 'echo -e "${RED}Error: Command failed at line $LINENO${NC}"' ERR

# Function to show usage
show_usage() {
    echo "Usage: $0 {start|stop|ssh|status|clean}"
    echo "  start  - Start the development environment"
    echo "  stop   - Stop the development environment"
    echo "  ssh    - Connect to the development container"
    echo "  status - Show environment status"
    echo "  clean  - Clean up Docker resources"
}

# Function to check remote connection
check_remote_connection() {
    echo -e "${YELLOW}Checking remote connection...${NC}"
    if ! ssh -q ${REMOTE_HOST} exit; then
        echo -e "${RED}Error: Cannot connect to remote host ${REMOTE_HOST}${NC}"
        exit 1
    fi
}

# Function to check if container is running
check_container_status() {
    echo -e "${YELLOW}Checking container status...${NC}"
    if ! ssh ${REMOTE_HOST} "cd ${PROJECT_DIR}/linux_docker_dev && docker-compose ps | grep -q 'running'"; then
        echo -e "${RED}Error: Container is not running${NC}"
        return 1
    fi
    return 0
}

# Function to start development environment
start_env() {
    echo -e "${YELLOW}Starting development environment...${NC}"
    check_remote_connection
    
    # Start container
    ssh ${REMOTE_HOST} "cd ${PROJECT_DIR}/linux_docker_dev && docker-compose up -d"
    echo -e "${YELLOW}Waiting for SSH server to start...${NC}"
    sleep 5
    
    # Add container's host key to known_hosts
    ssh ${REMOTE_HOST} "ssh-keyscan -p ${DOCKER_PORT} localhost >> ~/.ssh/known_hosts 2>/dev/null"
    
    if check_container_status; then
        echo -e "${GREEN}Development environment started successfully${NC}"
    else
        echo -e "${RED}Failed to start development environment${NC}"
        exit 1
    fi
}

# Function to stop development environment
stop_env() {
    echo -e "${YELLOW}Stopping development environment...${NC}"
    check_remote_connection
    ssh ${REMOTE_HOST} "cd ${PROJECT_DIR}/linux_docker_dev && docker-compose down"
    echo -e "${GREEN}Development environment stopped${NC}"
}

# Function to clean up Docker resources
clean_env() {
    echo -e "${YELLOW}Cleaning up Docker resources...${NC}"
    check_remote_connection
    ssh ${REMOTE_HOST} "cd ${PROJECT_DIR}/linux_docker_dev && \
        docker-compose down && \
        docker network prune -f && \
        docker system prune -f"
    echo -e "${GREEN}Cleanup completed${NC}"
}

# Function to connect to development container
connect_container() {
    echo -e "${YELLOW}Connecting to development container...${NC}"
    check_remote_connection
    
    if ! check_container_status; then
        echo -e "${RED}Container is not running. Starting it now...${NC}"
        start_env
    fi
    
    ssh -t ${REMOTE_HOST} "docker exec -it cpp_project_dev_container /bin/bash"
}

# Function to show status
show_status() {
    echo -e "${YELLOW}Environment status:${NC}"
    check_remote_connection
    ssh ${REMOTE_HOST} "cd ${PROJECT_DIR}/linux_docker_dev && docker-compose ps"
}

# Main script
case "$1" in
    start)
        start_env
        ;;
    stop)
        stop_env
        ;;
    clean)
        clean_env
        ;;
    ssh)
        connect_container
        ;;
    status)
        show_status
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
