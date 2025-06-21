#!/bin/bash

# Cursor To OpenAI - Docker Build Script for Linux/Mac
echo "========================================="
echo "  Cursor To OpenAI Docker Builder       "
echo "========================================="

# Configuration
IMAGE_NAME="cursor-to-openai"
IMAGE_TAG="latest"
CONTAINER_NAME="cursor-to-openai-container"
PORT="3010"
REGISTRY_USER=""  # Set your Docker Hub username here

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        echo "Please install Docker from https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        echo "Please start Docker daemon"
        exit 1
    fi
    
    print_success "Docker is available"
}

# Build Docker image
build_image() {
    print_info "Building Docker image: $IMAGE_NAME:$IMAGE_TAG"
    
    # Create .dockerignore if it doesn't exist
    if [ ! -f ".dockerignore" ]; then
        print_info "Creating .dockerignore file"
        cat > .dockerignore << EOF
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.nyc_output
coverage
.DS_Store
logs
*.log
.vscode
scripts
EOF
    fi
    
    # Build the image
    if docker build -t "$IMAGE_NAME:$IMAGE_TAG" .; then
        print_success "Docker image built successfully"
        return 0
    else
        print_error "Failed to build Docker image"
        return 1
    fi
}

# Run container
run_container() {
    print_info "Running Docker container: $CONTAINER_NAME"
    
    # Stop and remove existing container if it exists
    if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_warning "Stopping and removing existing container"
        docker stop "$CONTAINER_NAME" 2>/dev/null
        docker rm "$CONTAINER_NAME" 2>/dev/null
    fi
    
    # Check if .env file exists
    ENV_MOUNT=""
    if [ -f ".env" ]; then
        ENV_MOUNT="-v $(pwd)/.env:/app/.env"
        print_info "Mounting .env file"
    else
        print_warning ".env file not found - container will run without environment variables"
    fi
    
    # Run the container
    if docker run -d \
        --name "$CONTAINER_NAME" \
        -p "$PORT:3010" \
        $ENV_MOUNT \
        "$IMAGE_NAME:$IMAGE_TAG"; then
        print_success "Container started successfully"
        print_info "Access the API at: http://localhost:$PORT"
        print_info "Container name: $CONTAINER_NAME"
        return 0
    else
        print_error "Failed to start container"
        return 1
    fi
}

# Stop container
stop_container() {
    print_info "Stopping container: $CONTAINER_NAME"
    if docker stop "$CONTAINER_NAME" 2>/dev/null; then
        print_success "Container stopped"
    else
        print_warning "Container was not running or does not exist"
    fi
}

# Remove container
remove_container() {
    print_info "Removing container: $CONTAINER_NAME"
    if docker rm "$CONTAINER_NAME" 2>/dev/null; then
        print_success "Container removed"
    else
        print_warning "Container does not exist"
    fi
}

# Show logs
show_logs() {
    print_info "Showing logs for container: $CONTAINER_NAME"
    if docker logs -f "$CONTAINER_NAME" 2>/dev/null; then
        return 0
    else
        print_error "Container does not exist or is not running"
        return 1
    fi
}

# Tag and push to registry
push_image() {
    if [ -z "$REGISTRY_USER" ]; then
        print_error "REGISTRY_USER is not set in this script"
        print_info "Please edit the script and set your Docker Hub username"
        return 1
    fi
    
    print_info "Tagging image for registry"
    docker tag "$IMAGE_NAME:$IMAGE_TAG" "$REGISTRY_USER/$IMAGE_NAME:$IMAGE_TAG"
    
    print_info "Pushing to Docker Hub: $REGISTRY_USER/$IMAGE_NAME:$IMAGE_TAG"
    if docker push "$REGISTRY_USER/$IMAGE_NAME:$IMAGE_TAG"; then
        print_success "Image pushed successfully"
        print_info "Pull command: docker pull $REGISTRY_USER/$IMAGE_NAME:$IMAGE_TAG"
    else
        print_error "Failed to push image"
        return 1
    fi
}

# Show container status
show_status() {
    print_info "Container status:"
    if docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -q "$CONTAINER_NAME"; then
        docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep "$CONTAINER_NAME"
    else
        print_warning "Container is not running"
    fi
    
    echo ""
    print_info "Available images:"
    docker images | grep "$IMAGE_NAME" || print_warning "No images found"
}

# Clean up
cleanup() {
    print_info "Cleaning up Docker resources"
    
    # Stop and remove container
    docker stop "$CONTAINER_NAME" 2>/dev/null
    docker rm "$CONTAINER_NAME" 2>/dev/null
    
    # Remove image
    if docker rmi "$IMAGE_NAME:$IMAGE_TAG" 2>/dev/null; then
        print_success "Image removed"
    else
        print_warning "Image does not exist"
    fi
    
    # Clean up unused resources
    print_info "Cleaning up unused Docker resources"
    docker system prune -f
}

# Show help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build     Build Docker image"
    echo "  run       Run Docker container"
    echo "  stop      Stop Docker container"
    echo "  restart   Restart Docker container"
    echo "  logs      Show container logs"
    echo "  status    Show container and image status"
    echo "  push      Push image to Docker Hub"
    echo "  cleanup   Stop container and remove image"
    echo "  help      Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 build"
    echo "  $0 run"
    echo "  $0 logs"
}

# Main script logic
case "${1:-help}" in
    "build")
        check_docker
        build_image
        ;;
    "run")
        check_docker
        build_image && run_container
        ;;
    "stop")
        check_docker
        stop_container
        ;;
    "restart")
        check_docker
        stop_container
        remove_container
        build_image && run_container
        ;;
    "logs")
        check_docker
        show_logs
        ;;
    "status")
        check_docker
        show_status
        ;;
    "push")
        check_docker
        push_image
        ;;
    "cleanup")
        check_docker
        cleanup
        ;;
    "help"|*)
        show_help
        ;;
esac

echo "=========================================" 