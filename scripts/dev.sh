#!/bin/bash

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'
readonly SERVICE_NAME="blog"

print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed."
        exit 1
    fi

    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not available."
        exit 1
    fi
}

start_dev() {
    print_message "Starting environment..."
    docker compose up --build -d
    print_message "Server at: http://localhost:1313"
}

stop_dev() {
    print_message "Stopping environment..."
    docker compose down
}

rebuild() {
    print_message "Rebuilding..."
    docker compose down
    docker compose build --no-cache
    docker compose up -d
}

logs() {
    docker compose logs -f
}

exec_command() {
    if [ -z "${1:-}" ]; then
        print_error "No command given"
        exit 1
    fi

    print_message "Running: $1"
    docker compose exec "$SERVICE_NAME" "$@"
}

generate_index() {
    print_message "Generating index..."
    docker compose exec "$SERVICE_NAME" ruby scripts/generate_index.rb
}

test_recommendations() {
    print_message "Testing chronological recommendations..."
    docker compose run --rm "$SERVICE_NAME" ruby scripts/test_chronological_next.rb
}

new_post() {
    # Runs locally (no Docker needed): see scripts/new_post.rb
    ruby "$(dirname "$0")/new_post.rb" "$@"
}

show_help() {
    echo "Commands:"
    echo "  start          - Start the environment"
    echo "  stop           - Stop the environment"
    echo "  restart        - Restart the environment"
    echo "  rebuild        - Rebuild the image"
    echo "  logs           - Show logs"
    echo "  exec <cmd>     - Run a command in the container"
    echo "  generate-index - Generate the post index"
    echo "  test-recommendations - Test chronological recommendations"
    echo "  new-post <title> [--tags a,b] - Create a new post (draft)"
    echo "  help           - Show this help"
}

main() {
    case "${1:-help}" in
        new-post|help|--help|-h) ;;
        *) check_docker ;;
    esac

    case "${1:-help}" in
        start)
            start_dev
            ;;
        stop)
            stop_dev
            ;;
        restart)
            stop_dev
            start_dev
            ;;
        rebuild)
            rebuild
            ;;
        logs)
            logs
            ;;
        exec)
            shift
            exec_command "$@"
            ;;
        generate-index)
            generate_index
            ;;
        test-recommendations)
            test_recommendations
            ;;
        new-post)
            shift
            new_post "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Comando desconhecido: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
