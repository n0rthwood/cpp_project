#!/bin/bash

case "$1" in
    start)
        echo "Starting development environment..."
        docker-compose up -d
        echo "Development environment is ready!"
        echo "Connect using: ssh -p 2222 developer@localhost"
        ;;
    stop)
        echo "Stopping development environment..."
        docker-compose down
        ;;
    restart)
        echo "Restarting development environment..."
        docker-compose restart
        ;;
    rebuild)
        echo "Rebuilding development environment..."
        docker-compose down
        docker-compose build --no-cache
        docker-compose up -d
        ;;
    status)
        echo "Development environment status:"
        docker-compose ps
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|rebuild|status}"
        exit 1
        ;;
esac
