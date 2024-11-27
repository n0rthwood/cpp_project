#!/bin/bash

# Configuration
IMAGE_NAME="cpp_project_dev"
CONTAINER_NAME="cpp_project_dev_container"
WORKSPACE_DIR="/opt/workspace/cpp_project"

# Function to show usage
show_usage() {
    echo "Usage: $0 {build|start|stop|restart|exec|status}"
    echo "  build   - Build the development Docker image"
    echo "  start   - Start the development container"
    echo "  stop    - Stop the development container"
    echo "  restart - Restart the development container"
    echo "  exec    - Execute a command in the container (default: bash)"
    echo "  status  - Show container status"
}

# Build the Docker image
build_image() {
    echo "Building development Docker image..."
    docker build -t ${IMAGE_NAME} .
}

# Start the container
start_container() {
    if [ "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
        echo "Container is already running"
        return
    fi

    if [ "$(docker ps -aq -f status=exited -f name=${CONTAINER_NAME})" ]; then
        echo "Starting existing container..."
        docker start ${CONTAINER_NAME}
    else
        echo "Creating and starting new container..."
        docker run -d \
            --name ${CONTAINER_NAME} \
            -v ${WORKSPACE_DIR}:/workspace \
            -w /workspace \
            --init \
            ${IMAGE_NAME} \
            sleep infinity
    fi
}

# Stop the container
stop_container() {
    echo "Stopping container..."
    docker stop ${CONTAINER_NAME}
}

# Execute a command in the container
exec_in_container() {
    if [ $# -eq 0 ]; then
        docker exec -it ${CONTAINER_NAME} /bin/bash
    else
        docker exec -it ${CONTAINER_NAME} "$@"
    fi
}

# Show container status
show_status() {
    echo "Container status:"
    docker ps -a | grep ${CONTAINER_NAME}
}

# Main script
case "$1" in
    build)
        build_image
        ;;
    start)
        start_container
        ;;
    stop)
        stop_container
        ;;
    restart)
        stop_container
        start_container
        ;;
    exec)
        shift
        exec_in_container "$@"
        ;;
    status)
        show_status
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
